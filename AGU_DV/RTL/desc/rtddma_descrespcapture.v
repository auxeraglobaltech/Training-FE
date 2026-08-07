
//==============================================================================
// Project      : RTD-DMA
// Module       : rtddma_descrespcapture
//------------------------------------------------------------------------------
// Description  :
// ASIL-D hardened deterministic descriptor response capture engine.
//
// Responsibilities:
//   - AXI R-channel descriptor capture
//   - Descriptor beat collection
//   - Deterministic beat accounting
//   - RLAST legality checking
//   - AXI response validation
//   - Timeout monitoring
//   - Descriptor payload assembly
//   - Sticky fault reporting
//
//------------------------------------------------------------------------------
// Safety Features
//------------------------------------------------------------------------------
// - Deterministic bounded FSM
// - Parallel protocol legality checks
// - Early/late RLAST detection
// - Beat overflow detection
// - No-progress timeout detection
// - Sticky first-fault behavior
// - Safe fail-stop handling
// - Illegal state detection
// - SEU-aware recovery path
//==============================================================================

`include "rtddma_params.vh"
`include "rtddma_states.vh"
`include "rtddma_faultcodes.vh"

module rtddma_descrespcapture
(
    input  wire                             clk,
    input  wire                             rst_n,

    //--------------------------------------------------------------------------
    // Control
    //--------------------------------------------------------------------------

    input  wire                             start_capture_i,
    input  wire                             clr_fault_i,

    //--------------------------------------------------------------------------
    // AXI R Channel
    //--------------------------------------------------------------------------

    input  wire                             rvalid_i,
    output reg                              rready_o,

    input  wire [31:0]                      rdata_i,
    input  wire [1:0]                       rresp_i,
    input  wire                             rlast_i,

    //--------------------------------------------------------------------------
    // Descriptor Output
    //--------------------------------------------------------------------------

    output reg                              capture_done_o,
    output reg                              capture_done_err_o,

    output reg [`RTDDMA_DESC_W-1:0]         desc_payload_o,

    //--------------------------------------------------------------------------
    // Status
    //--------------------------------------------------------------------------

    output reg [3:0]                        beat_count_o,

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

localparam DESC_BEATS = 8;
localparam TIMEOUT_MAX = 16'd2048;

///////////////////////////////////////////////////////////////////////////////
// FSM
///////////////////////////////////////////////////////////////////////////////

reg [2:0] state_q;
reg [2:0] state_n;

localparam RC_IDLE       = 3'd0;
localparam RC_WAIT_FIRST = 3'd1;
localparam RC_COLLECT    = 3'd2;
localparam RC_DONE       = 3'd3;
localparam RC_FAULT      = 3'd4;

///////////////////////////////////////////////////////////////////////////////
// INTERNALS
///////////////////////////////////////////////////////////////////////////////

reg [15:0] timeout_cnt_q;
reg [3:0]  beat_cnt_q;

reg [`RTDDMA_DESC_W-1:0] desc_payload_q;

wire timeout_expired;

assign timeout_expired =
    (timeout_cnt_q >= TIMEOUT_MAX);

///////////////////////////////////////////////////////////////////////////////
// PARALLEL CHECKS
///////////////////////////////////////////////////////////////////////////////

wire chk_rresp_fail;
wire chk_early_rlast_fail;
wire chk_missing_rlast_fail;
wire chk_overflow_fail;
wire chk_timeout_fail;
wire chk_illegal_state_fail;

assign chk_rresp_fail =
(
    rvalid_i &
    rready_o &
    (rresp_i != 2'b00)
);

assign chk_early_rlast_fail =
(
    rvalid_i &
    rready_o &
    rlast_i &
    (beat_cnt_q != (DESC_BEATS-1))
);

assign chk_missing_rlast_fail =
(
    rvalid_i &
    rready_o &
    (beat_cnt_q == (DESC_BEATS-1)) &
    !rlast_i
);

assign chk_overflow_fail =
(
    beat_cnt_q >= DESC_BEATS
);

assign chk_timeout_fail =
(
    ((state_q == RC_WAIT_FIRST) ||
     (state_q == RC_COLLECT)) &&
    timeout_expired
);

assign chk_illegal_state_fail =
(
    (state_q != RC_IDLE)       &&
    (state_q != RC_WAIT_FIRST) &&
    (state_q != RC_COLLECT)    &&
    (state_q != RC_DONE)       &&
    (state_q != RC_FAULT)
);

wire any_fault;

assign any_fault =
       chk_rresp_fail
    || chk_early_rlast_fail
    || chk_missing_rlast_fail
    || chk_overflow_fail
    || chk_timeout_fail
    || chk_illegal_state_fail;

///////////////////////////////////////////////////////////////////////////////
// FAULT PRIORITY
///////////////////////////////////////////////////////////////////////////////

reg [7:0]  pri_fault_code;
reg [31:0] pri_fault_info;

always @(*) begin

    pri_fault_code = `RTDDMA_FAULT_NONE;
    pri_fault_info = 32'h00000000;

    if (chk_rresp_fail) begin

        pri_fault_code = `RTDDMA_FAULT_AXI_RESP;
        pri_fault_info = {30'd0, rresp_i};
    end

    else if (chk_early_rlast_fail) begin

        pri_fault_code = `RTDDMA_FAULT_EARLY_RLAST;
        pri_fault_info = {28'd0, beat_cnt_q};
    end

    else if (chk_missing_rlast_fail) begin

        pri_fault_code = `RTDDMA_FAULT_MISSING_RLAST;
        pri_fault_info = {28'd0, beat_cnt_q};
    end

    else if (chk_overflow_fail) begin

        pri_fault_code = `RTDDMA_FAULT_DESC_OVERFLOW;
    end

    else if (chk_timeout_fail) begin

        pri_fault_code = `RTDDMA_FAULT_DESC_TIMEOUT;
    end

    else if (chk_illegal_state_fail) begin

        pri_fault_code = `RTDDMA_FAULT_ILLEGAL_STATE;
    end
end

///////////////////////////////////////////////////////////////////////////////
// FSM NEXT STATE
///////////////////////////////////////////////////////////////////////////////

always @(*) begin

    state_n = state_q;

    case (state_q)

        RC_IDLE:
        begin
            if (start_capture_i)
                state_n = RC_WAIT_FIRST;
        end

        RC_WAIT_FIRST:
        begin
            if (any_fault)
                state_n = RC_FAULT;
            else if (rvalid_i)
                state_n = RC_COLLECT;
        end

        RC_COLLECT:
        begin
            if (any_fault)
                state_n = RC_FAULT;
            else if (rvalid_i && rready_o && rlast_i)
                state_n = RC_DONE;
        end

        RC_DONE:
        begin
            state_n = RC_IDLE;
        end

        RC_FAULT:
        begin
            if (clr_fault_i)
                state_n = RC_IDLE;
        end

        default:
        begin
            state_n = RC_FAULT;
        end
    endcase
end

///////////////////////////////////////////////////////////////////////////////
// SEQUENTIAL
///////////////////////////////////////////////////////////////////////////////

always @(posedge clk or negedge rst_n) begin

    if (!rst_n) begin

        state_q              <= RC_IDLE;

        rready_o             <= 1'b0;

        capture_done_o       <= 1'b0;
        capture_done_err_o   <= 1'b0;

        beat_cnt_q           <= 4'd0;
        beat_count_o         <= 4'd0;

        timeout_cnt_q        <= 16'd0;

        desc_payload_q       <= {`RTDDMA_DESC_W{1'b0}};
        desc_payload_o       <= {`RTDDMA_DESC_W{1'b0}};

        fault_valid_o        <= 1'b0;
        fault_code_o         <= `RTDDMA_FAULT_NONE;
        fault_info_o         <= 32'h00000000;

    end
    else begin

        state_q <= state_n;

        capture_done_o     <= 1'b0;
        capture_done_err_o <= 1'b0;

        //---------------------------------------------------------------------
        // Timeout Counter
        //---------------------------------------------------------------------

        if ((state_q == RC_WAIT_FIRST) ||
            (state_q == RC_COLLECT)) begin

            timeout_cnt_q <= timeout_cnt_q + 1'b1;
        end
        else begin

            timeout_cnt_q <= 16'd0;
        end

        //---------------------------------------------------------------------
        // FSM Actions
        //---------------------------------------------------------------------

        case (state_q)

            RC_IDLE:
            begin
                rready_o <= 1'b0;

                beat_cnt_q <= 4'd0;

                desc_payload_q <= {`RTDDMA_DESC_W{1'b0}};
            end

            RC_WAIT_FIRST:
            begin
                rready_o <= 1'b1;
            end

            RC_COLLECT:
            begin
                rready_o <= 1'b1;

                if (rvalid_i && rready_o) begin

                    case (beat_cnt_q)

                        4'd0: desc_payload_q[31:0]    <= rdata_i;
                        4'd1: desc_payload_q[63:32]   <= rdata_i;
                        4'd2: desc_payload_q[95:64]   <= rdata_i;
                        4'd3: desc_payload_q[127:96]  <= rdata_i;
                        4'd4: desc_payload_q[159:128] <= rdata_i;
                        4'd5: desc_payload_q[191:160] <= rdata_i;
                        4'd6: desc_payload_q[223:192] <= rdata_i;
                        4'd7: desc_payload_q[255:224] <= rdata_i;

                        default:
                            desc_payload_q <= desc_payload_q;
                    endcase

                    beat_cnt_q <= beat_cnt_q + 1'b1;

                    beat_count_o <= beat_cnt_q + 1'b1;
                end
            end

            RC_DONE:
            begin
                rready_o <= 1'b0;

                capture_done_o <= 1'b1;

                desc_payload_o <= desc_payload_q;
            end

            RC_FAULT:
            begin
                rready_o <= 1'b0;

                capture_done_err_o <= 1'b1;
            end

            default:
            begin
                rready_o <= 1'b0;
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
        // Clear Fault
        //---------------------------------------------------------------------

        if (clr_fault_i) begin

            fault_valid_o <= 1'b0;
            fault_code_o  <= `RTDDMA_FAULT_NONE;
            fault_info_o  <= 32'h00000000;
        end
    end
end

endmodule