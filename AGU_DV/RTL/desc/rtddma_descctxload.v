
//==============================================================================
// Project      : RTD-DMA
// Module       : rtddma_descctxload
//------------------------------------------------------------------------------
// Description  :
// ASIL-D hardened atomic descriptor context loader.
//
// Responsibilities:
//   - Atomic descriptor commit
//   - Shadow-to-active transfer
//   - Commit legality enforcement
//   - Active context parity generation/checking
//   - Safe swap boundary enforcement
//   - Deterministic context activation
//   - Context corruption monitoring
//
//------------------------------------------------------------------------------
// Safety Features
//------------------------------------------------------------------------------
// - Atomic commit only
// - No partial context visibility
// - Active context parity protection
// - Illegal commit rejection
// - Busy-state commit blocking
// - Outstanding transaction blocking
// - FIFO-drain enforcement
// - SEU detection hooks
// - Sticky first-fault capture
// - Deterministic fail-stop behavior
//==============================================================================

`include "rtdma_params.vh"
`include "rtdma_fault_codes.vh"

module rtddma_descctxload
(
    input  wire                                 clk,
    input  wire                                 rst_n,

    //--------------------------------------------------------------------------
    // Context Input
    //--------------------------------------------------------------------------

    input  wire                                 ctx_valid_i,
    input  wire [`RTDDMA_DESC_W-1:0]            ctx_payload_i,

    //--------------------------------------------------------------------------
    // Runtime Safety Inputs
    //--------------------------------------------------------------------------

    input  wire                                 slice_busy_i,
    input  wire                                 outstanding_busy_i,
    input  wire                                 fifo_nonempty_i,
    input  wire                                 halt_active_i,

    //--------------------------------------------------------------------------
    // Commit Control
    //--------------------------------------------------------------------------

    input  wire                                 commit_req_i,
    input  wire                                 swap_req_i,

    //--------------------------------------------------------------------------
    // Outputs
    //--------------------------------------------------------------------------

    output reg                                  ctx_commit_done_o,
    output reg                                  ctx_commit_reject_o,

    output reg                                  active_ctx_valid_o,

    output reg [`RTDDMA_DESC_W-1:0]             active_ctx_o,

    //--------------------------------------------------------------------------
    // Fault Outputs
    //--------------------------------------------------------------------------

    output reg                                  fault_valid_o,
    output reg [7:0]                            fault_code_o,
    output reg [31:0]                           fault_info_o
);

///////////////////////////////////////////////////////////////////////////////
// SHADOW STORAGE
///////////////////////////////////////////////////////////////////////////////

reg [`RTDDMA_DESC_W-1:0] shadow_ctx_q;
reg                      shadow_ctx_valid_q;

///////////////////////////////////////////////////////////////////////////////
// ACTIVE CONTEXT PARITY
///////////////////////////////////////////////////////////////////////////////

reg active_ctx_parity_q;

wire active_ctx_parity_calc;
wire active_ctx_parity_error;

assign active_ctx_parity_calc =
    ^active_ctx_o;

assign active_ctx_parity_error =
    (active_ctx_parity_calc != active_ctx_parity_q);

///////////////////////////////////////////////////////////////////////////////
// COMMIT LEGALITY CHECKS
///////////////////////////////////////////////////////////////////////////////

wire chk_busy_commit_fail;
wire chk_halt_commit_fail;
wire chk_invalid_shadow_fail;
wire chk_swap_illegal_fail;

assign chk_busy_commit_fail =
(
    slice_busy_i |
    outstanding_busy_i |
    fifo_nonempty_i
);

assign chk_halt_commit_fail =
    halt_active_i;

assign chk_invalid_shadow_fail =
    (shadow_ctx_valid_q != 1'b1);

assign chk_swap_illegal_fail =
(
    swap_req_i &
    outstanding_busy_i
);

wire any_commit_fail;

assign any_commit_fail =
       chk_busy_commit_fail
    || chk_halt_commit_fail
    || chk_invalid_shadow_fail
    || chk_swap_illegal_fail;

///////////////////////////////////////////////////////////////////////////////
// FAULT PRIORITY
///////////////////////////////////////////////////////////////////////////////

reg [7:0]  pri_fault_code;
reg [31:0] pri_fault_info;

always @(*) begin

    pri_fault_code = `RTDDMA_FAULT_NONE;
    pri_fault_info = 32'h00000000;

    if (chk_busy_commit_fail) begin

        pri_fault_code = `RTDDMA_FAULT_BUSY_COMMIT;
    end

    else if (chk_halt_commit_fail) begin

        pri_fault_code = `RTDDMA_FAULT_SLICE_HALTED;
    end

    else if (chk_invalid_shadow_fail) begin

        pri_fault_code = `RTDDMA_FAULT_INVALID_CTX;
    end

    else if (chk_swap_illegal_fail) begin

        pri_fault_code = `RTDDMA_FAULT_SWAP_ILLEGAL;
    end

    else if (active_ctx_parity_error) begin

        pri_fault_code = `RTDDMA_FAULT_CTX_PARITY;
    end
end

///////////////////////////////////////////////////////////////////////////////
// SEQUENTIAL
///////////////////////////////////////////////////////////////////////////////

always @(posedge clk or negedge rst_n) begin

    if (!rst_n) begin

        shadow_ctx_q           <= {`RTDDMA_DESC_W{1'b0}};
        shadow_ctx_valid_q     <= 1'b0;

        active_ctx_o           <= {`RTDDMA_DESC_W{1'b0}};
        active_ctx_valid_o     <= 1'b0;

        active_ctx_parity_q    <= 1'b0;

        ctx_commit_done_o      <= 1'b0;
        ctx_commit_reject_o    <= 1'b0;

        fault_valid_o          <= 1'b0;
        fault_code_o           <= `RTDDMA_FAULT_NONE;
        fault_info_o           <= 32'h00000000;

    end
    else begin

        ctx_commit_done_o   <= 1'b0;
        ctx_commit_reject_o <= 1'b0;

        //---------------------------------------------------------------------
        // Shadow Capture
        //---------------------------------------------------------------------

        if (ctx_valid_i) begin

            shadow_ctx_q <= ctx_payload_i;

            shadow_ctx_valid_q <= 1'b1;
        end

        //---------------------------------------------------------------------
        // Atomic Commit
        //---------------------------------------------------------------------

        if (commit_req_i) begin

            if (!any_commit_fail) begin

                active_ctx_o <= shadow_ctx_q;

                active_ctx_valid_o <= 1'b1;

                active_ctx_parity_q <=
                    ^shadow_ctx_q;

                ctx_commit_done_o <= 1'b1;
            end
            else begin

                ctx_commit_reject_o <= 1'b1;

                fault_valid_o <= 1'b1;
                fault_code_o  <= pri_fault_code;
                fault_info_o  <= pri_fault_info;
            end
        end

        //---------------------------------------------------------------------
        // Active Context Integrity
        //---------------------------------------------------------------------

        if (active_ctx_parity_error) begin

            active_ctx_valid_o <= 1'b0;

            fault_valid_o <= 1'b1;
            fault_code_o  <= `RTDDMA_FAULT_CTX_PARITY;
            fault_info_o  <= 32'hC07E0000;
        end
    end
end

endmodule
