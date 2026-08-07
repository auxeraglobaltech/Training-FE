
//==============================================================================
// File        : rtddma_agutop.v
// Project     : RTD-DMA
//------------------------------------------------------------------------------
// Description :
// Top-level deterministic AGU subsystem.
//
// Responsibilities:
// - Integrates AGU execution chain
// - Descriptor-driven address generation
// - Burst planning
// - Bounds enforcement
// - Pipeline staging
// - Ping/pong coordination
// - Safety containment
//
// Pipeline:
//   AGU_CORE
//      -> LINE_CTRL
//      -> BURST_PLAN
//      -> BOUNDS_CHECK
//      -> ADDR_PIPE
//
// Safety:
// - Deterministic bounded latency
// - No speculative issue
// - Backpressure-safe
// - Fault containment
// - SEU-safe fail-close defaults
//
//==============================================================================
`timescale 1ns/1ps

`include "rtddmaparams.vh"
`include "rtddma_descfields.vh"
`include "rtddmafaultcodes.vh"
`include "rtddmastates.vh"

module rtddma_agutop
(
    input  wire                                     clk,
    input  wire                                     rst_n,

    //--------------------------------------------------------------------------
    // CONTROL
    //--------------------------------------------------------------------------

    input  wire                                     start_i,
    input  wire                                     stop_i,
    input  wire                                     clr_fault_i,

    //--------------------------------------------------------------------------
    // DESCRIPTOR CONTEXT
    //--------------------------------------------------------------------------

    input  wire [31:0]                              desc_w0_i,
    input  wire [31:0]                              desc_w1_i,
    input  wire [31:0]                              desc_w2_i,
    input  wire [31:0]                              desc_w3_i,
    input  wire [31:0]                              desc_w4_i,
    input  wire [31:0]                              desc_w5_i,
    input  wire [31:0]                              desc_w6_i,

    //--------------------------------------------------------------------------
    // MPU REGION LIMITS
    //--------------------------------------------------------------------------

    input  wire [39:0]                              src_region_base_i,
    input  wire [39:0]                              src_region_limit_i,

    input  wire [39:0]                              dst_region_base_i,
    input  wire [39:0]                              dst_region_limit_i,

    //--------------------------------------------------------------------------
    // ISSUE SIDE
    //--------------------------------------------------------------------------

    input  wire                                     issue_ready_i,
    input  wire                                     issue_ack_i,

    input  wire [3:0]                               outstanding_cnt_i,

    //--------------------------------------------------------------------------
    // OUTPUT TO ISSUE ENGINE
    //--------------------------------------------------------------------------

    output wire                                     agu_valid_o,

    output wire [39:0]                              agu_src_addr_o,
    output wire [39:0]                              agu_dst_addr_o,

    output wire [15:0]                              agu_burst_bytes_o,

    //--------------------------------------------------------------------------
    // STATUS
    //--------------------------------------------------------------------------

    output wire                                     agu_busy_o,
    output wire                                     agu_done_o,

    //--------------------------------------------------------------------------
    // FAULTS
    //--------------------------------------------------------------------------

    output wire                                     fault_valid_o,
    output wire [7:0]                               fault_code_o,
    output wire [31:0]                              fault_info_o
);

///////////////////////////////////////////////////////////////////////////////
// DESCRIPTOR DECODE
///////////////////////////////////////////////////////////////////////////////

wire [1:0] src_width;
wire [1:0] dst_width;

wire [3:0] burst_len;

wire [1:0] burst_type;
wire [1:0] addr_mode;

wire [15:0] x_count;
wire [15:0] x_stride;

wire [15:0] y_count;
wire [15:0] y_stride;

///////////////////////////////////////////////////////////////////////////////
// W0
///////////////////////////////////////////////////////////////////////////////

assign src_width =
    desc_w0_i[`RTDDMA_W0_SRC_WIDTH_MSB:
              `RTDDMA_W0_SRC_WIDTH_LSB];

assign dst_width =
    desc_w0_i[`RTDDMA_W0_DST_WIDTH_MSB:
              `RTDDMA_W0_DST_WIDTH_LSB];

assign burst_len =
    desc_w0_i[`RTDDMA_W0_BURST_LEN_MSB:
              `RTDDMA_W0_BURST_LEN_LSB];

assign burst_type =
    desc_w0_i[`RTDDMA_W0_BURST_TYPE_MSB:
              `RTDDMA_W0_BURST_TYPE_LSB];

assign addr_mode =
    desc_w0_i[`RTDDMA_W0_ADDR_MODE_MSB:
              `RTDDMA_W0_ADDR_MODE_LSB];

///////////////////////////////////////////////////////////////////////////////
// W3 / W4
///////////////////////////////////////////////////////////////////////////////

assign x_count  = desc_w3_i[31:16];
assign x_stride = desc_w3_i[15:0];

assign y_count  = desc_w4_i[31:16];
assign y_stride = desc_w4_i[15:0];

///////////////////////////////////////////////////////////////////////////////
// INTERNAL CONNECTIONS
///////////////////////////////////////////////////////////////////////////////

wire             core_valid;

wire [39:0]      core_src_addr;
wire [39:0]      core_dst_addr;

wire [15:0]      core_x_idx;
wire [15:0]      core_y_idx;

wire             core_done;

wire [15:0] core_burst_bytes;
wire        core_line_done;
wire        core_busy;

wire core_ready;
wire core_issue_ack;
wire burst_ack;

wire             line_valid;

wire [39:0]      line_src_addr;
wire [39:0]      line_dst_addr;

wire             burst_valid;

wire [39:0]      burst_src_addr;
wire [39:0]      burst_dst_addr;

wire [39:0] burst_src_end;
wire [39:0] burst_dst_end;

wire [15:0]      burst_bytes;


wire             bounds_valid;
wire             bounds_pass;

wire             pipe_fault_valid;
wire [7:0]       pipe_fault_code;
wire [31:0]      pipe_fault_info;

wire             bounds_fault_valid;
wire [7:0]       bounds_fault_code;
wire [31:0]      bounds_fault_info;

//---------------------------------------------------------------------------
// Core fault signals
//---------------------------------------------------------------------------
wire        core_fault_valid;
wire [7:0]  core_fault_code;
wire [31:0] core_fault_info;

//---------------------------------------------------------------------------
// Line controller fault signals
//---------------------------------------------------------------------------
wire        line_fault_valid;
wire [7:0]  line_fault_code;
wire [31:0] line_fault_info;

//---------------------------------------------------------------------------
// Burst planner fault signals
//---------------------------------------------------------------------------
wire        burst_fault_valid;
wire [7:0]  burst_fault_code;
wire [31:0] burst_fault_info;

wire [15:0] x_remaining;
wire        burst_busy;
wire        burst_input_ready;
wire        pipe_busy;
wire pipe_addr_ready;
reg         core_done_seen;

wire [7:0]  axi_arlen;
wire [7:0]  axi_awlen;

wire [2:0]  axi_arsize;
wire [2:0]  axi_awsize;

wire [1:0]  axi_arburst;
wire [1:0]  axi_awburst;

assign x_remaining =
    (x_count > core_x_idx) ? (x_count - core_x_idx) : 16'd0;

assign core_ready     =  burst_input_ready;
assign core_issue_ack =  core_valid && burst_input_ready;
assign burst_ack =burst_valid && bounds_valid && bounds_pass && pipe_addr_ready;

assign burst_src_end = burst_src_addr + burst_bytes - 1'b1;
assign burst_dst_end = burst_dst_addr + burst_bytes - 1'b1;

///////////////////////////////////////////////////////////////////////////////
// AGU CORE
///////////////////////////////////////////////////////////////////////////////

rtddma_agucore2d u_rtddma_agucore2d (
    .clk             (clk),
    .rst_n            (rst_n),

    .start_i           (start_i),
    .stop_i            (stop_i),
    .pause_i           (1'b0),
    .drain_i           (1'b0),
    .clr_fault_i       (clr_fault_i),

    .src_addr_i        (desc_w1_i),
    .dst_addr_i        (desc_w2_i),

    .x_count_i         (x_count),
    .y_count_i         (y_count),
    .x_stride_i        (x_stride),
    .y_stride_i        (y_stride),

    .burst_len_i       (burst_len),
    //.burst_type_i      (burst_type),
    .src_width_i       (src_width),
    .dst_width_i       (dst_width),
    .gather_enable_i        (1'b0),
    .scatter_enable_i       (1'b0),

    .gather_ptr_i           (32'd0),
    .scatter_ptr_i          (32'd0),
    .addr_mode_i       (addr_mode),

    .issue_ack_i       (core_issue_ack),
    .downstream_ready_i(core_ready),

    .issue_valid_o      (core_valid),
    .src_addr_o        (core_src_addr),
    .dst_addr_o        (core_dst_addr),
    .burst_bytes_o     (core_burst_bytes),

    .line_done_o       (core_line_done),
    .frame_done_o      (core_done),
    .busy_o            (core_busy),

    .x_idx_o           (core_x_idx),
    .y_idx_o           (core_y_idx),

    .fault_valid_o     (core_fault_valid),
    .fault_code_o      (core_fault_code),
    .fault_info_o      (core_fault_info)
);

///////////////////////////////////////////////////////////////////////////////
// LINE CTRL
///////////////////////////////////////////////////////////////////////////////

rtddma_agulinectrl u_rtddma_agulinectrl
(
    .clk             (clk),
    .rst_n           (rst_n),

    .start_i         (start_i),
    .stop_i          (stop_i),
    .clr_fault_i     (clr_fault_i),

    .addr_valid_i    (core_valid),
    .src_addr_i      (core_src_addr),
    .dst_addr_i      (core_dst_addr),

    .x_idx_i         (core_x_idx),
    .y_idx_i         (core_y_idx),
    .x_count_i       (x_count),
    .y_count_i       (y_count),

    .line_valid_o    (line_valid),
    .line_src_addr_o (line_src_addr),
    .line_dst_addr_o (line_dst_addr),

    .line_start_o    (),
    .line_end_o      (),
    .line_x_idx_o    (),
    .line_y_idx_o    (),
    .busy_o          (),
    .done_o          (),

    .fault_valid_o   (line_fault_valid),
    .fault_code_o    (line_fault_code),
    .fault_info_o    (line_fault_info)    
);

///////////////////////////////////////////////////////////////////////////////
// BURST PLAN
///////////////////////////////////////////////////////////////////////////////

rtddma_aguburstplan u_rtddma_aguburstplan (
    .clk                (clk),
    .rst_n              (rst_n),

    .start_i            (start_i),
    .stop_i             (stop_i),
    .clr_fault_i        (clr_fault_i),

    .addr_valid_i       (line_valid),
    .addr_ready_o       (burst_input_ready),
    .src_addr_i         (line_src_addr),
    .dst_addr_i         (line_dst_addr),

    .burst_len_i        (burst_len),
    .burst_type_i       (burst_type),
    .src_width_i        (src_width),
    .dst_width_i        (dst_width),

    .x_remaining_i      (x_remaining),
    .outstanding_cnt_i  (outstanding_cnt_i),
    .issue_ack_i        (burst_ack),

    .burst_valid_o      (burst_valid),
    .burst_src_addr_o   (burst_src_addr),
    .burst_dst_addr_o   (burst_dst_addr),

    .axi_arlen_o        (axi_arlen),
    .axi_awlen_o        (axi_awlen),
    .axi_arsize_o       (axi_arsize),
    .axi_awsize_o       (axi_awsize),
    .axi_arburst_o      (axi_arburst),
    .axi_awburst_o      (axi_awburst),

    .burst_bytes_o      (burst_bytes),
    .planner_busy_o     (burst_busy),

    .fault_valid_o      (burst_fault_valid),
    .fault_code_o       (burst_fault_code),
    .fault_info_o       (burst_fault_info)
);

///////////////////////////////////////////////////////////////////////////////
// BOUNDS CHECK
///////////////////////////////////////////////////////////////////////////////

rtddma_aguboundschk u_rtddma_aguboundschk
(
    .clk                    (clk),
    .rst_n                  (rst_n),

    .start_i                (start_i),
    .clr_fault_i            (clr_fault_i),

    .addr_valid_i           (burst_valid),

    .src_addr_i             (burst_src_addr),
    .dst_addr_i             (burst_dst_addr),

    .src_end_addr_i         (burst_src_end),
    .dst_end_addr_i         (burst_dst_end),

    .src_region_base_i      (src_region_base_i),
    .src_region_limit_i     (src_region_limit_i),

    .dst_region_base_i      (dst_region_base_i),
    .dst_region_limit_i     (dst_region_limit_i),

    .burst_bytes_i          (burst_bytes),

    .addr_mode_i            (addr_mode),

    .gather_enable_i        (addr_mode == 2'b10),
    .scatter_enable_i       (addr_mode == 2'b11),

    .bounds_valid_o         (bounds_valid),
    .bounds_pass_o          (bounds_pass),

    .fault_valid_o          (bounds_fault_valid),
    .fault_code_o           (bounds_fault_code),
    .fault_info_o           (bounds_fault_info)
);

///////////////////////////////////////////////////////////////////////////////
// ADDRESS PIPE
///////////////////////////////////////////////////////////////////////////////

rtddma_aguaddrpipe u_rtddma_aguaddrpipe
(
    .clk                    (clk),
    .rst_n                  (rst_n),

    .start_i                (start_i),
    .stop_i                 (stop_i),
    .clr_fault_i            (clr_fault_i),

    .addr_valid_i           (bounds_valid & bounds_pass),
    .addr_ready_o           (pipe_addr_ready),

    .src_addr_i             (burst_src_addr),
    .dst_addr_i             (burst_dst_addr),

    .burst_bytes_i          (burst_bytes),

    .issue_ready_i          (issue_ready_i),
    .issue_ack_i            (issue_ack_i),

    .outstanding_cnt_i      (outstanding_cnt_i),

    .pipe_valid_o           (agu_valid_o),

    .pipe_src_addr_o        (agu_src_addr_o),
    .pipe_dst_addr_o        (agu_dst_addr_o),

    .pipe_burst_bytes_o     (agu_burst_bytes_o),

    .pipe_busy_o            (pipe_busy),
    .pipe_stall_o           (),

    .fault_valid_o          (pipe_fault_valid),
    .fault_code_o           (pipe_fault_code),
    .fault_info_o           (pipe_fault_info)
);

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        core_done_seen <= 1'b0;
    end
    else begin
        // A new operation clears completion history.
        if (start_i)
            core_done_seen <= 1'b0;

        // Remember the core completion pulse until the pipeline drains.
        else if (core_done)
            core_done_seen <= 1'b1;

        // Clear after the top-level completion pulse is generated.
        else if (agu_done_o)
            core_done_seen <= 1'b0;
    end
end

///////////////////////////////////////////////////////////////////////////////
// DONE
///////////////////////////////////////////////////////////////////////////////

/*assign agu_done_o =
(
    core_done &&
    !fault_valid_o
);

///////////////////////////////////////////////////////////////////////////////
// FAULT AGGREGATION
///////////////////////////////////////////////////////////////////////////////

assign fault_valid_o =
(
       bounds_fault_valid
    || pipe_fault_valid
);

assign fault_code_o =
(
    bounds_fault_valid
)
?
    bounds_fault_code
:
    pipe_fault_code;

assign fault_info_o =
(
    bounds_fault_valid
)
?
    bounds_fault_info
:
    pipe_fault_info;*/

assign agu_busy_o =
       core_busy
    || burst_busy
    || pipe_busy
    || agu_valid_o;

assign agu_done_o =
       core_done_seen
    && !burst_busy
    && !pipe_busy
    && !agu_valid_o
    && !fault_valid_o;
assign fault_valid_o =
       core_fault_valid
    || line_fault_valid
    || burst_fault_valid
    || bounds_fault_valid
    || pipe_fault_valid;

assign fault_code_o =
    core_fault_valid   ? core_fault_code   :
    line_fault_valid   ? line_fault_code   :
    burst_fault_valid  ? burst_fault_code  :
    bounds_fault_valid ? bounds_fault_code :
    pipe_fault_valid   ? pipe_fault_code   :
                         8'h00;

assign fault_info_o =
    core_fault_valid   ? core_fault_info   :
    line_fault_valid   ? line_fault_info   :
    burst_fault_valid  ? burst_fault_info  :
    bounds_fault_valid ? bounds_fault_info :
    pipe_fault_valid   ? pipe_fault_info   :
                         32'h0000_0000;

//assign fault_valid_o = core_fault_valid;
//assign fault_code_o  = core_fault_code;
//assign fault_info_o  = core_fault_info;

endmodule
