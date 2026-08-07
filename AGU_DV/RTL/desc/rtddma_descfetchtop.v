
//==============================================================================
// Project      : RTD-DMA
// Module       : rtddma_descfetchtop
//------------------------------------------------------------------------------
// Description  :
// ASIL-D hardened deterministic descriptor fetch supervisor.
//
// This module orchestrates the complete descriptor pipeline:
//
//   reqgen
//      ->
//   respcapture
//      ->
//   parser
//      ->
//   crcchk
//      ->
//   validator
//      ->
//   ctxload
//
// Responsibilities:
//   - Descriptor transaction ownership
//   - Deterministic descriptor sequencing
//   - Timeout ownership
//   - Safe halt/flush behavior
//   - Commit orchestration
//   - Fault containment
//   - Anti-double-fetch protection
//   - Descriptor lifecycle management
//
//==============================================================================

`include "rtddma_params.vh"
`include "rtddma_states.vh"
`include "rtddma_faultcodes.vh"

module rtddma_descfetchtop
(
    input  wire                             clk,
    input  wire                             rst_n,

    //--------------------------------------------------------------------------
    // Descriptor Control
    //--------------------------------------------------------------------------

    input  wire                             start_fetch_i,
    input  wire                             halt_req_i,
    input  wire                             clr_fault_i,

    input  wire [`RTDDMA_ADDR_W-1:0]        desc_addr_i,

    //--------------------------------------------------------------------------
    // Request Generator Interface
    //--------------------------------------------------------------------------

    output reg                              reqgen_start_o,
    output reg [`RTDDMA_ADDR_W-1:0]         reqgen_addr_o,

    input  wire                             reqgen_done_i,
    input  wire                             reqgen_fault_i,

    //--------------------------------------------------------------------------
    // Response Capture Interface
    //--------------------------------------------------------------------------

    output reg                              respcap_start_o,

    input  wire                             respcap_done_i,
    input  wire                             respcap_fault_i,

    input  wire [`RTDDMA_DESC_W-1:0]        desc_payload_i,

    //--------------------------------------------------------------------------
    // Parser Interface
    //--------------------------------------------------------------------------

    output reg                              parser_start_o,

    input  wire                             parser_done_i,
    input  wire                             parser_fault_i,

    //--------------------------------------------------------------------------
    // CRC Interface
    //--------------------------------------------------------------------------

    output reg                              crc_start_o,

    input  wire                             crc_done_i,
    input  wire                             crc_fault_i,

    //--------------------------------------------------------------------------
    // Validator Interface
    //--------------------------------------------------------------------------

    output reg                              validator_start_o,

    input  wire                             validator_done_i,
    input  wire                             validator_fault_i,

    //--------------------------------------------------------------------------
    // Context Loader Interface
    //--------------------------------------------------------------------------

    output reg                              ctxload_commit_o,

    input  wire                             ctxload_done_i,
    input  wire                             ctxload_fault_i,

    //--------------------------------------------------------------------------
    // Outputs
    //--------------------------------------------------------------------------

    output reg                              fetch_done_o,
    output reg                              fetch_busy_o,

    output reg                              desc_valid_o,

    //--------------------------------------------------------------------------
    // Fault Outputs
    //--------------------------------------------------------------------------

    output reg                              fault_valid_o,
    output reg [7:0]                        fault_code_o,
    output reg [31:0]                       fault_info_o
);

///////////////////////////////////////////////////////////////////////////////
// LOCALPARAMS
///////////////////////////////////////////////////////////////////////////////

localparam DF_IDLE        = 4'd0;
localparam DF_REQ         = 4'd1;
localparam DF_WAIT_RESP   = 4'd2;
localparam DF_PARSE       = 4'd3;
localparam DF_CRC         = 4'd4;
localparam DF_VALIDATE    = 4'd5;
localparam DF_COMMIT      = 4'd6;
localparam DF_DONE        = 4'd7;
localparam DF_FAULT       = 4'd8;
localparam DF_HALT        = 4'd9;

localparam FETCH_TIMEOUT = 16'd4096;

///////////////////////////////////////////////////////////////////////////////
// INTERNALS
///////////////////////////////////////////////////////////////////////////////

reg [3:0] state_q;
reg [3:0] state_n;

reg [15:0] timeout_cnt_q;

reg inflight_q;

wire timeout_expired;

assign timeout_expired =
    (timeout_cnt_q >= FETCH_TIMEOUT);

///////////////////////////////////////////////////////////////////////////////
// PARALLEL FAULT CHECKS
///////////////////////////////////////////////////////////////////////////////

wire chk_double_fetch_fail;
wire chk_timeout_fail;
wire chk_illegal_state_fail;

assign chk_double_fetch_fail =
(
    start_fetch_i &
    inflight_q
);

assign chk_timeout_fail =
(
    (state_q != DF_IDLE) &&
    (state_q != DF_DONE) &&
    timeout_expired
);

assign chk_illegal_state_fail =
(
    (state_q != DF_IDLE)      &&
    (state_q != DF_REQ)       &&
    (state_q != DF_WAIT_RESP) &&
    (state_q != DF_PARSE)     &&
    (state_q != DF_CRC)       &&
    (state_q != DF_VALIDATE)  &&
    (state_q != DF_COMMIT)    &&
    (state_q != DF_DONE)      &&
    (state_q != DF_FAULT)     &&
    (state_q != DF_HALT)
);

wire submodule_fault;

assign submodule_fault =
       reqgen_fault_i
    || respcap_fault_i
    || parser_fault_i
    || crc_fault_i
    || validator_fault_i
    || ctxload_fault_i;

wire any_fault;

assign any_fault =
       chk_double_fetch_fail
    || chk_timeout_fail
    || chk_illegal_state_fail
    || submodule_fault;

///////////////////////////////////////////////////////////////////////////////
// FAULT PRIORITY
///////////////////////////////////////////////////////////////////////////////

reg [7:0]  pri_fault_code;
reg [31:0] pri_fault_info;

always @(*) begin

    pri_fault_code = `RTDDMA_FAULT_NONE;
    pri_fault_info = 32'h00000000;

    if (chk_double_fetch_fail) begin

        pri_fault_code = `RTDDMA_FAULT_DOUBLE_FETCH;
    end

    else if (chk_timeout_fail) begin

        pri_fault_code = `RTDDMA_FAULT_DESC_TIMEOUT;
    end

    else if (chk_illegal_state_fail) begin

        pri_fault_code = `RTDDMA_FAULT_ILLEGAL_STATE;
    end

    else if (reqgen_fault_i) begin

        pri_fault_code = `RTDDMA_FAULT_REQGEN;
    end

    else if (respcap_fault_i) begin

        pri_fault_code = `RTDDMA_FAULT_RESPCAP;
    end

    else if (parser_fault_i) begin

        pri_fault_code = `RTDDMA_FAULT_PARSER;
    end

    else if (crc_fault_i) begin

        pri_fault_code = `RTDDMA_FAULT_DESC_CRC;
    end

    else if (validator_fault_i) begin

        pri_fault_code = `RTDDMA_FAULT_DESC_VALIDATION;
    end

    else if (ctxload_fault_i) begin

        pri_fault_code = `RTDDMA_FAULT_CTXLOAD;
    end
end

///////////////////////////////////////////////////////////////////////////////
// FSM NEXT STATE
///////////////////////////////////////////////////////////////////////////////

always @(*) begin

    state_n = state_q;

    case (state_q)

        DF_IDLE:
        begin
            if (halt_req_i)
                state_n = DF_HALT;
            else if (start_fetch_i)
                state_n = DF_REQ;
        end

        DF_REQ:
        begin
            if (any_fault)
                state_n = DF_FAULT;
            else if (reqgen_done_i)
                state_n = DF_WAIT_RESP;
        end

        DF_WAIT_RESP:
        begin
            if (any_fault)
                state_n = DF_FAULT;
            else if (respcap_done_i)
                state_n = DF_PARSE;
        end

        DF_PARSE:
        begin
            if (any_fault)
                state_n = DF_FAULT;
            else if (parser_done_i)
                state_n = DF_CRC;
        end

        DF_CRC:
        begin
            if (any_fault)
                state_n = DF_FAULT;
            else if (crc_done_i)
                state_n = DF_VALIDATE;
        end

        DF_VALIDATE:
        begin
            if (any_fault)
                state_n = DF_FAULT;
            else if (validator_done_i)
                state_n = DF_COMMIT;
        end

        DF_COMMIT:
        begin
            if (any_fault)
                state_n = DF_FAULT;
            else if (ctxload_done_i)
                state_n = DF_DONE;
        end

        DF_DONE:
        begin
            state_n = DF_IDLE;
        end

        DF_FAULT:
        begin
            if (clr_fault_i)
                state_n = DF_IDLE;
        end

        DF_HALT:
        begin
            if (!halt_req_i)
                state_n = DF_IDLE;
        end

        default:
        begin
            state_n = DF_FAULT;
        end
    endcase
end

///////////////////////////////////////////////////////////////////////////////
// SEQUENTIAL
///////////////////////////////////////////////////////////////////////////////

always @(posedge clk or negedge rst_n) begin

    if (!rst_n) begin

        state_q <= DF_IDLE;

        reqgen_start_o    <= 1'b0;
        reqgen_addr_o     <= {`RTDDMA_ADDR_W{1'b0}};

        respcap_start_o   <= 1'b0;
        parser_start_o    <= 1'b0;
        crc_start_o       <= 1'b0;
        validator_start_o <= 1'b0;
        ctxload_commit_o  <= 1'b0;

        fetch_done_o      <= 1'b0;
        fetch_busy_o      <= 1'b0;
        desc_valid_o      <= 1'b0;

        inflight_q        <= 1'b0;

        timeout_cnt_q     <= 16'd0;

        fault_valid_o     <= 1'b0;
        fault_code_o      <= `RTDDMA_FAULT_NONE;
        fault_info_o      <= 32'h00000000;

    end
    else begin

        state_q <= state_n;

        reqgen_start_o    <= 1'b0;
        respcap_start_o   <= 1'b0;
        parser_start_o    <= 1'b0;
        crc_start_o       <= 1'b0;
        validator_start_o <= 1'b0;
        ctxload_commit_o  <= 1'b0;

        fetch_done_o      <= 1'b0;

        //---------------------------------------------------------------------
        // Timeout Counter
        //---------------------------------------------------------------------

        if (state_q != DF_IDLE &&
            state_q != DF_DONE &&
            state_q != DF_FAULT) begin

            timeout_cnt_q <= timeout_cnt_q + 1'b1;
        end
        else begin

            timeout_cnt_q <= 16'd0;
        end

        //---------------------------------------------------------------------
        // FSM Actions
        //---------------------------------------------------------------------

        case (state_q)

            DF_IDLE:
            begin
                fetch_busy_o <= 1'b0;
                inflight_q   <= 1'b0;
            end

            DF_REQ:
            begin
                fetch_busy_o <= 1'b1;

                reqgen_start_o <= 1'b1;
                reqgen_addr_o  <= desc_addr_i;

                inflight_q <= 1'b1;
            end

            DF_WAIT_RESP:
            begin
                respcap_start_o <= 1'b1;
            end

            DF_PARSE:
            begin
                parser_start_o <= 1'b1;
            end

            DF_CRC:
            begin
                crc_start_o <= 1'b1;
            end

            DF_VALIDATE:
            begin
                validator_start_o <= 1'b1;
            end

            DF_COMMIT:
            begin
                ctxload_commit_o <= 1'b1;
            end

            DF_DONE:
            begin
                fetch_done_o  <= 1'b1;
                desc_valid_o  <= 1'b1;
                fetch_busy_o  <= 1'b0;
                inflight_q    <= 1'b0;
            end

            DF_FAULT:
            begin
                fetch_busy_o <= 1'b0;
                inflight_q   <= 1'b0;
                desc_valid_o <= 1'b0;
            end

            DF_HALT:
            begin
                fetch_busy_o <= 1'b0;
            end

            default:
            begin
                fetch_busy_o <= 1'b0;
            end
        endcase

        //---------------------------------------------------------------------
        // Fault Handling
        //---------------------------------------------------------------------

        if (any_fault) begin

            fault_valid_o <= 1'b1;
            fault_code_o  <= pri_fault_code;
            fault_info_o  <= pri_fault_info;
        end

        //---------------------------------------------------------------------
        // Fault Clear
        //---------------------------------------------------------------------

        if (clr_fault_i) begin

            fault_valid_o <= 1'b0;
            fault_code_o  <= `RTDDMA_FAULT_NONE;
            fault_info_o  <= 32'h00000000;
        end
    end
end

endmodule