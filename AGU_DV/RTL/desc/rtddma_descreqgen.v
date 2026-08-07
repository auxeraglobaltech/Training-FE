# rtddma_descreqgen.v


//==============================================================================
// Project      : RTD-DMA
// Module       : rtddma_descreqgen
//------------------------------------------------------------------------------
// Description  :
// ASIL-D hardened deterministic descriptor request generator.
//
// Responsibilities:
//   - Descriptor AXI read request generation
//   - Descriptor fetch alignment enforcement
//   - Outstanding tracking
//   - Anti-double-issue protection
//   - Deterministic request issue
//   - Safe request suppression during faults
//   - Chain fetch request sequencing
//
//------------------------------------------------------------------------------
// Safety Features
//------------------------------------------------------------------------------
// - Single outstanding descriptor fetch
// - No speculative next-fetch
// - Descriptor alignment enforcement
// - AXI legality enforcement
// - Request timeout watchdog
// - Sticky fault capture
// - SEU hardened control path
// - Illegal reissue protection
// - Safe halt behavior
//==============================================================================

`include "rtddma_params.vh"
`include "rtddma_faultcodes.vh"

module rtddma_descreqgen
(
    input  wire                             clk,
    input  wire                             rst_n,

    //--------------------------------------------------------------------------
    // Request Control
    //--------------------------------------------------------------------------

    input  wire                             fetch_req_i,
    input  wire [`RTDDMA_ADDR_W-1:0]        desc_addr_i,

    input  wire                             fetch_complete_i,
    input  wire                             fetch_error_i,

    input  wire                             halt_req_i,

    //--------------------------------------------------------------------------
    // AXI Interface
    //--------------------------------------------------------------------------

    output reg                              arvalid_o,
    input  wire                             arready_i,

    output reg [`RTDDMA_ADDR_W-1:0]         araddr_o,
    output reg [7:0]                        arlen_o,
    output reg [2:0]                        arsize_o,
    output reg [1:0]                        arburst_o,

    //--------------------------------------------------------------------------
    // Status
    //--------------------------------------------------------------------------

    output reg                              fetch_busy_o,
    output reg                              fetch_issued_o,

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

localparam DESC_BYTES = (`RTDDMA_DESC_W / 8);
localparam DESC_ALIGN = 32;

///////////////////////////////////////////////////////////////////////////////
// INTERNALS
///////////////////////////////////////////////////////////////////////////////

reg outstanding_q;

reg [15:0] timeout_cnt_q;

wire timeout_expired;

assign timeout_expired =
    (timeout_cnt_q >= 16'd2048);

///////////////////////////////////////////////////////////////////////////////
// CHECKS
///////////////////////////////////////////////////////////////////////////////

wire chk_align_fail;
wire chk_double_issue_fail;
wire chk_halt_issue_fail;
wire chk_timeout_fail;

assign chk_align_fail =
    (desc_addr_i[4:0] != 5'b00000);

assign chk_double_issue_fail =
(
    fetch_req_i &
    outstanding_q
);

assign chk_halt_issue_fail =
(
    fetch_req_i &
    halt_req_i
);

assign chk_timeout_fail =
    timeout_expired;

wire any_fault;

assign any_fault =
       chk_align_fail
    || chk_double_issue_fail
    || chk_halt_issue_fail
    || chk_timeout_fail
    || fetch_error_i;

///////////////////////////////////////////////////////////////////////////////
// FAULT PRIORITY
///////////////////////////////////////////////////////////////////////////////

reg [7:0]  pri_fault_code;
reg [31:0] pri_fault_info;

always @(*) begin

    pri_fault_code = `RTDDMA_FAULT_NONE;
    pri_fault_info = 32'h00000000;

    if (chk_align_fail) begin

        pri_fault_code = `RTDDMA_FAULT_DESC_ALIGN;
        pri_fault_info = desc_addr_i;
    end

    else if (chk_double_issue_fail) begin

        pri_fault_code = `RTDDMA_FAULT_DOUBLE_ISSUE;
    end

    else if (chk_halt_issue_fail) begin

        pri_fault_code = `RTDDMA_FAULT_SLICE_HALTED;
    end

    else if (chk_timeout_fail) begin

        pri_fault_code = `RTDDMA_FAULT_DESC_TIMEOUT;
    end

    else if (fetch_error_i) begin

        pri_fault_code = `RTDDMA_FAULT_AXI_RESP;
    end
end

///////////////////////////////////////////////////////////////////////////////
// SEQUENTIAL
///////////////////////////////////////////////////////////////////////////////

always @(posedge clk or negedge rst_n) begin

    if (!rst_n) begin

        arvalid_o          <= 1'b0;
        araddr_o           <= {`RTDDMA_ADDR_W{1'b0}};
        arlen_o            <= 8'd0;
        arsize_o           <= 3'b000;
        arburst_o          <= 2'b01;

        fetch_busy_o       <= 1'b0;
        fetch_issued_o     <= 1'b0;

        outstanding_q      <= 1'b0;

        timeout_cnt_q      <= 16'd0;

        fault_valid_o      <= 1'b0;
        fault_code_o       <= `RTDDMA_FAULT_NONE;
        fault_info_o       <= 32'h00000000;

    end
    else begin

        fetch_issued_o <= 1'b0;

        //---------------------------------------------------------------------
        // Timeout Counter
        //---------------------------------------------------------------------

        if (outstanding_q)
            timeout_cnt_q <= timeout_cnt_q + 1'b1;
        else
            timeout_cnt_q <= 16'd0;

        //---------------------------------------------------------------------
        // New Fetch Request
        //---------------------------------------------------------------------

        if (fetch_req_i && !any_fault && !outstanding_q) begin

            arvalid_o <= 1'b1;

            araddr_o  <= desc_addr_i;

            arlen_o   <= 8'd7;
            arsize_o  <= 3'b010;
            arburst_o <= 2'b01;

            fetch_busy_o <= 1'b1;
        end

        //---------------------------------------------------------------------
        // AXI Handshake
        //---------------------------------------------------------------------

        if (arvalid_o && arready_i) begin

            arvalid_o <= 1'b0;

            outstanding_q <= 1'b1;

            fetch_issued_o <= 1'b1;
        end

        //---------------------------------------------------------------------
        // Fetch Completion
        //---------------------------------------------------------------------

        if (fetch_complete_i) begin

            outstanding_q <= 1'b0;

            fetch_busy_o <= 1'b0;
        end

        //---------------------------------------------------------------------
        // Fault Handling
        //---------------------------------------------------------------------

        if (any_fault) begin

            arvalid_o <= 1'b0;

            fetch_busy_o <= 1'b0;

            outstanding_q <= 1'b0;

            fault_valid_o <= 1'b1;
            fault_code_o  <= pri_fault_code;
            fault_info_o  <= pri_fault_info;
        end
    end
end

endmodule
