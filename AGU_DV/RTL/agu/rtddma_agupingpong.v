
//==============================================================================
// File        : rtddma_agupingpong.v
// Project     : RTD-DMA
//------------------------------------------------------------------------------
// Description :
// Deterministic ping-pong context manager for AGU.
//
// Responsibilities:
// - Manage ACTIVE/PENDING context banks
// - Deterministic context swapping
// - Atomic shadow->active commit
// - Ping/pong execution isolation
// - Prevent partial descriptor visibility
// - Safe context rollover
// - Backpressure-aware swap gating
//
// Safety:
// - Dual-bank coherency checks
// - Illegal swap prevention
// - SEU-safe FSM
// - No speculative context activation
// - No inferred latches
// - Pure synthesizable Verilog
//
//==============================================================================

`include "rtddma_params.vh"
`include "rtddma_faultcodes.vh"
`include "rtddma_states.vh"

module rtddma_agupingpong
(
    input  wire                                     clk,
    input  wire                                     rst_n,

    //--------------------------------------------------------------------------
    // CONTROL
    //--------------------------------------------------------------------------

    input  wire                                     cfg_commit_i,
    input  wire                                     swap_req_i,
    input  wire                                     swap_enable_i,

    input  wire                                     issue_idle_i,
    input  wire                                     outstanding_empty_i,

    input  wire                                     clr_fault_i,

    //--------------------------------------------------------------------------
    // SHADOW CONTEXT INPUT
    //--------------------------------------------------------------------------

    input  wire [31:0]                              shadow_w0_i,
    input  wire [31:0]                              shadow_w1_i,
    input  wire [31:0]                              shadow_w2_i,
    input  wire [31:0]                              shadow_w3_i,
    input  wire [31:0]                              shadow_w4_i,
    input  wire [31:0]                              shadow_w5_i,
    input  wire [31:0]                              shadow_w6_i,
    input  wire [31:0]                              shadow_w7_i,

    //--------------------------------------------------------------------------
    // ACTIVE OUTPUT CONTEXT
    //--------------------------------------------------------------------------

    output reg [31:0]                               active_w0_o,
    output reg [31:0]                               active_w1_o,
    output reg [31:0]                               active_w2_o,
    output reg [31:0]                               active_w3_o,
    output reg [31:0]                               active_w4_o,
    output reg [31:0]                               active_w5_o,
    output reg [31:0]                               active_w6_o,
    output reg [31:0]                               active_w7_o,

    //--------------------------------------------------------------------------
    // STATUS
    //--------------------------------------------------------------------------

    output reg                                      ping_active_o,
    output reg                                      pong_active_o,

    output reg                                      swap_done_o,
    output reg                                      ctx_valid_o,

    //--------------------------------------------------------------------------
    // FAULTS
    //--------------------------------------------------------------------------

    output reg                                      fault_valid_o,
    output reg [7:0]                                fault_code_o,
    output reg [31:0]                               fault_info_o
);

///////////////////////////////////////////////////////////////////////////////
// INTERNAL CONTEXT BANKS
///////////////////////////////////////////////////////////////////////////////

reg [31:0] ping_w0_q;
reg [31:0] ping_w1_q;
reg [31:0] ping_w2_q;
reg [31:0] ping_w3_q;
reg [31:0] ping_w4_q;
reg [31:0] ping_w5_q;
reg [31:0] ping_w6_q;
reg [31:0] ping_w7_q;

reg [31:0] pong_w0_q;
reg [31:0] pong_w1_q;
reg [31:0] pong_w2_q;
reg [31:0] pong_w3_q;
reg [31:0] pong_w4_q;
reg [31:0] pong_w5_q;
reg [31:0] pong_w6_q;
reg [31:0] pong_w7_q;

///////////////////////////////////////////////////////////////////////////////
// FSM
///////////////////////////////////////////////////////////////////////////////

reg [2:0] state_q;
reg [2:0] state_n;

///////////////////////////////////////////////////////////////////////////////
// SAFETY CHECKS
///////////////////////////////////////////////////////////////////////////////

wire chk_swap_while_busy;
wire chk_invalid_bank;
wire chk_commit_without_enable;
wire chk_illegal_state;

assign chk_swap_while_busy =
(
    swap_req_i &&
    (
        !issue_idle_i ||
        !outstanding_empty_i
    )
);

assign chk_invalid_bank =
(
    ping_active_o &&
    pong_active_o
);

assign chk_commit_without_enable =
(
    cfg_commit_i &&
    !swap_enable_i
);

assign chk_illegal_state =
(
    (state_q != `RTDDMA_IDLE_S)  &&
    (state_q != `RTDDMA_BUSY_S)  &&
    (state_q != `RTDDMA_DONE_S)  &&
    (state_q != `RTDDMA_FAULT_S)
);

wire any_fault;

assign any_fault =
       chk_swap_while_busy
    || chk_invalid_bank
    || chk_commit_without_enable
    || chk_illegal_state;

///////////////////////////////////////////////////////////////////////////////
// FSM NEXT STATE
///////////////////////////////////////////////////////////////////////////////

always @(*) begin

    state_n = state_q;

    case (state_q)

        `RTDDMA_IDLE_S:
        begin
            if (cfg_commit_i)
                state_n = `RTDDMA_BUSY_S;
        end

        `RTDDMA_BUSY_S:
        begin

            if (any_fault)
                state_n = `RTDDMA_FAULT_S;

            else
                state_n = `RTDDMA_DONE_S;
        end

        `RTDDMA_DONE_S:
        begin
            state_n = `RTDDMA_IDLE_S;
        end

        `RTDDMA_FAULT_S:
        begin

            if (clr_fault_i)
                state_n = `RTDDMA_IDLE_S;
        end

        default:
        begin
            state_n = `RTDDMA_FAULT_S;
        end

    endcase
end

///////////////////////////////////////////////////////////////////////////////
// SEQUENTIAL
///////////////////////////////////////////////////////////////////////////////

always @(posedge clk or negedge rst_n) begin

    if (!rst_n) begin

        state_q <= `RTDDMA_IDLE_S;

        ping_active_o <= 1'b1;
        pong_active_o <= 1'b0;

        swap_done_o <= 1'b0;
        ctx_valid_o <= 1'b0;

        active_w0_o <= 32'd0;
        active_w1_o <= 32'd0;
        active_w2_o <= 32'd0;
        active_w3_o <= 32'd0;
        active_w4_o <= 32'd0;
        active_w5_o <= 32'd0;
        active_w6_o <= 32'd0;
        active_w7_o <= 32'd0;

        fault_valid_o <= 1'b0;
        fault_code_o  <= `RTDDMA_FAULT_NONE;
        fault_info_o  <= 32'd0;

    end
    else begin

        state_q <= state_n;

        swap_done_o <= 1'b0;

        case (state_q)

            //------------------------------------------------------------------
            // IDLE
            //------------------------------------------------------------------

            `RTDDMA_IDLE_S:
            begin

                if
                (
                    cfg_commit_i &&
                    swap_enable_i
                ) begin

                    //------------------------------------------------------------------
                    // LOAD INTO INACTIVE BANK
                    //------------------------------------------------------------------

                    if (ping_active_o) begin

                        pong_w0_q <= shadow_w0_i;
                        pong_w1_q <= shadow_w1_i;
                        pong_w2_q <= shadow_w2_i;
                        pong_w3_q <= shadow_w3_i;
                        pong_w4_q <= shadow_w4_i;
                        pong_w5_q <= shadow_w5_i;
                        pong_w6_q <= shadow_w6_i;
                        pong_w7_q <= shadow_w7_i;

                    end
                    else begin

                        ping_w0_q <= shadow_w0_i;
                        ping_w1_q <= shadow_w1_i;
                        ping_w2_q <= shadow_w2_i;
                        ping_w3_q <= shadow_w3_i;
                        ping_w4_q <= shadow_w4_i;
                        ping_w5_q <= shadow_w5_i;
                        ping_w6_q <= shadow_w6_i;
                        ping_w7_q <= shadow_w7_i;

                    end
                end
            end

            //------------------------------------------------------------------
            // BUSY
            //------------------------------------------------------------------

            `RTDDMA_BUSY_S:
            begin

                if (!any_fault) begin

                    //------------------------------------------------------------------
                    // ATOMIC SWAP
                    //------------------------------------------------------------------

                    if (swap_req_i) begin

                        if (ping_active_o) begin

                            ping_active_o <= 1'b0;
                            pong_active_o <= 1'b1;

                            active_w0_o <= pong_w0_q;
                            active_w1_o <= pong_w1_q;
                            active_w2_o <= pong_w2_q;
                            active_w3_o <= pong_w3_q;
                            active_w4_o <= pong_w4_q;
                            active_w5_o <= pong_w5_q;
                            active_w6_o <= pong_w6_q;
                            active_w7_o <= pong_w7_q;

                        end
                        else begin

                            ping_active_o <= 1'b1;
                            pong_active_o <= 1'b0;

                            active_w0_o <= ping_w0_q;
                            active_w1_o <= ping_w1_q;
                            active_w2_o <= ping_w2_q;
                            active_w3_o <= ping_w3_q;
                            active_w4_o <= ping_w4_q;
                            active_w5_o <= ping_w5_q;
                            active_w6_o <= ping_w6_q;
                            active_w7_o <= ping_w7_q;

                        end

                        ctx_valid_o <= 1'b1;
                        swap_done_o <= 1'b1;

                    end
                end
            end

            //------------------------------------------------------------------
            // DONE
            //------------------------------------------------------------------

            `RTDDMA_DONE_S:
            begin

                swap_done_o <= 1'b0;

            end

            //------------------------------------------------------------------
            // FAULT
            //------------------------------------------------------------------

            `RTDDMA_FAULT_S:
            begin

                fault_valid_o <= 1'b1;

                if (chk_swap_while_busy)
                    fault_code_o <= `RTDDMA_FAULT_CTX_SWAP_BUSY;

                else if (chk_invalid_bank)
                    fault_code_o <= `RTDDMA_FAULT_CTX_BANK_CORRUPT;

                else if (chk_commit_without_enable)
                    fault_code_o <= `RTDDMA_FAULT_CFG_COMMIT;

                else
                    fault_code_o <= `RTDDMA_FAULT_FSM_ILLEGAL_STATE;

                fault_info_o <= 32'h50494E47;

                if (clr_fault_i) begin

                    fault_valid_o <= 1'b0;
                    fault_code_o  <= `RTDDMA_FAULT_NONE;
                    fault_info_o  <= 32'd0;

                end
            end
        endcase
    end
end

endmodule
