//==============================================================================
// Project      : RTD-DMA
// Module       : rtddma_descchainctrl
//------------------------------------------------------------------------------
// Description  :
// ASIL-D hardened deterministic descriptor chain controller.
//
// Responsibilities:
//   - Descriptor chain ownership
//   - EOC handling
//   - Chain progression
//   - Anti-replay enforcement
//   - Loop/runaway prevention
//   - Trigger-wait chaining
//   - Ping-pong swap coordination
//   - Deterministic chain sequencing
//   - Safe next-descriptor issue
//
//==============================================================================

`include "rtddma_params.vh"
`include "rtddma_faultcodes.vh"

module rtddma_descchainctrl
(
    input  wire                             clk,
    input  wire                             rst_n,

    //--------------------------------------------------------------------------
    // Descriptor Completion Interface
    //--------------------------------------------------------------------------

    input  wire                             desc_complete_i,

    input  wire [31:0]                      link_cfg_i,
    input  wire [8:0]                       seq_id_i,

    input  wire                             validator_pass_i,

    //--------------------------------------------------------------------------
    // Trigger Interface
    //--------------------------------------------------------------------------

    input  wire                             trigger_i,

    //--------------------------------------------------------------------------
    // Outputs To FetchTop
    //--------------------------------------------------------------------------

    output reg                              next_fetch_req_o,
    output reg [31:0]                       next_desc_addr_o,

    output reg                              swap_req_o,

    output reg                              chain_done_o,

    //--------------------------------------------------------------------------
    // Fault Outputs
    //--------------------------------------------------------------------------

    output reg                              fault_valid_o,
    output reg [7:0]                        fault_code_o,
    output reg [31:0]                       fault_info_o
);

///////////////////////////////////////////////////////////////////////////////
// LINK CFG
///////////////////////////////////////////////////////////////////////////////

wire [26:0] next_desc_addr_w;
wire        eoc_w;
wire        swap_en_w;
wire        int_en_w;
wire [1:0]  link_mode_w;

assign next_desc_addr_w = link_cfg_i[31:5];
assign eoc_w            = link_cfg_i[4];
assign swap_en_w        = link_cfg_i[3];
assign int_en_w         = link_cfg_i[2];
assign link_mode_w      = link_cfg_i[1:0];

///////////////////////////////////////////////////////////////////////////////
// FSM
///////////////////////////////////////////////////////////////////////////////

localparam CH_IDLE          = 4'd0;
localparam CH_WAIT_COMPLETE = 4'd1;
localparam CH_EVAL_LINK     = 4'd2;
localparam CH_WAIT_TRIGGER  = 4'd3;
localparam CH_REQUEST_NEXT  = 4'd4;
localparam CH_DONE          = 4'd5;
localparam CH_FAULT         = 4'd6;

reg [3:0] state_q;
reg [3:0] state_n;

///////////////////////////////////////////////////////////////////////////////
// INTERNALS
///////////////////////////////////////////////////////////////////////////////

reg [8:0] expected_seq_q;

reg [15:0] chain_depth_q;

localparam MAX_CHAIN_DEPTH = 16'd1024;

///////////////////////////////////////////////////////////////////////////////
// PARALLEL CHECKS
///////////////////////////////////////////////////////////////////////////////

wire chk_seq_fail;
wire chk_depth_fail;
wire chk_self_link_fail;
wire chk_align_fail;
wire chk_illegal_state_fail;

assign chk_seq_fail =
    (seq_id_i != expected_seq_q);

assign chk_depth_fail =
    (chain_depth_q >= MAX_CHAIN_DEPTH);

assign chk_self_link_fail =
(
    next_desc_addr_w ==
    next_desc_addr_o[31:5]
);

assign chk_align_fail =
    (next_desc_addr_w[1:0] != 2'b00);

assign chk_illegal_state_fail =
(
    (state_q != CH_IDLE)          &&
    (state_q != CH_WAIT_COMPLETE) &&
    (state_q != CH_EVAL_LINK)     &&
    (state_q != CH_WAIT_TRIGGER)  &&
    (state_q != CH_REQUEST_NEXT)  &&
    (state_q != CH_DONE)          &&
    (state_q != CH_FAULT)
);

wire any_fault;

assign any_fault =
       chk_seq_fail
    || chk_depth_fail
    || chk_self_link_fail
    || chk_align_fail
    || chk_illegal_state_fail;

///////////////////////////////////////////////////////////////////////////////
// FAULT PRIORITY
///////////////////////////////////////////////////////////////////////////////

reg [7:0]  pri_fault_code;
reg [31:0] pri_fault_info;

always @(*) begin

    pri_fault_code = `RTDDMA_FAULT_NONE;
    pri_fault_info = 32'h00000000;

    if (chk_seq_fail) begin

        pri_fault_code = `RTDDMA_FAULT_SEQ;
        pri_fault_info = {23'd0, seq_id_i};
    end

    else if (chk_depth_fail) begin

        pri_fault_code = `RTDDMA_FAULT_CHAIN_DEPTH;
    end

    else if (chk_self_link_fail) begin

        pri_fault_code = `RTDDMA_FAULT_CHAIN_LOOP;
    end

    else if (chk_align_fail) begin

        pri_fault_code = `RTDDMA_FAULT_DESC_ALIGN;
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

        CH_IDLE:
        begin
            if (validator_pass_i)
                state_n = CH_WAIT_COMPLETE;
        end

        CH_WAIT_COMPLETE:
        begin
            if (any_fault)
                state_n = CH_FAULT;
            else if (desc_complete_i)
                state_n = CH_EVAL_LINK;
        end

        CH_EVAL_LINK:
        begin
            if (any_fault)
                state_n = CH_FAULT;

            else if (eoc_w)
                state_n = CH_DONE;

            else if (link_mode_w == 2'b01)
                state_n = CH_WAIT_TRIGGER;

            else
                state_n = CH_REQUEST_NEXT;
        end

        CH_WAIT_TRIGGER:
        begin
            if (any_fault)
                state_n = CH_FAULT;
            else if (trigger_i)
                state_n = CH_REQUEST_NEXT;
        end

        CH_REQUEST_NEXT:
        begin
            state_n = CH_WAIT_COMPLETE;
        end

        CH_DONE:
        begin
            state_n = CH_IDLE;
        end

        CH_FAULT:
        begin
            state_n = CH_FAULT;
        end

        default:
        begin
            state_n = CH_FAULT;
        end
    endcase
end

///////////////////////////////////////////////////////////////////////////////
// SEQUENTIAL
///////////////////////////////////////////////////////////////////////////////

always @(posedge clk or negedge rst_n) begin

    if (!rst_n) begin

        state_q <= CH_IDLE;

        next_fetch_req_o  <= 1'b0;
        next_desc_addr_o  <= 32'h00000000;

        swap_req_o        <= 1'b0;

        chain_done_o      <= 1'b0;

        expected_seq_q    <= 9'd0;

        chain_depth_q     <= 16'd0;

        fault_valid_o     <= 1'b0;
        fault_code_o      <= `RTDDMA_FAULT_NONE;
        fault_info_o      <= 32'h00000000;

    end
    else begin

        state_q <= state_n;

        next_fetch_req_o <= 1'b0;
        swap_req_o       <= 1'b0;
        chain_done_o     <= 1'b0;

        //---------------------------------------------------------------------
        // FSM Actions
        //---------------------------------------------------------------------

        case (state_q)

            CH_IDLE:
            begin
                chain_depth_q <= 16'd0;
            end

            CH_EVAL_LINK:
            begin
                if (swap_en_w)
                    swap_req_o <= 1'b1;
            end

            CH_REQUEST_NEXT:
            begin
                next_fetch_req_o <= 1'b1;

                next_desc_addr_o <=
                {
                    next_desc_addr_w,
                    5'b00000
                };

                expected_seq_q <= expected_seq_q + 1'b1;

                chain_depth_q <= chain_depth_q + 1'b1;
            end

            CH_DONE:
            begin
                chain_done_o <= 1'b1;
            end

            default:
            begin
            end
        endcase

        //---------------------------------------------------------------------
        // Fault Handling
        //---------------------------------------------------------------------

        if (any_fault) begin

            fault_valid_o <= 1'b1;

            fault_code_o <= pri_fault_code;

            fault_info_o <= pri_fault_info;
        end
    end
end

endmodule

