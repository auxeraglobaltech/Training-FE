// ============================================================
//  tb_top_vx_uvm — UVM top: clock/reset, rtlsim_shim DUT (1-core),
//  interface binding, run_test(). Reset follows processor.cpp:
//  8 cycles asserted + settle handled by the test.
// ============================================================
`timescale 1ns/1ps
`include "VX_config.vh"

module tb_top_vx_uvm;

  import uvm_pkg::*;
  import vx_tb_pkg::*;

  localparam int DATA_SIZE      = `VX_CFG_PLATFORM_MEMORY_DATA_SIZE;
  localparam int MEM_DATA_WIDTH = DATA_SIZE * 8;
  localparam int MEM_NUM_BANKS  = `VX_CFG_PLATFORM_MEMORY_NUM_BANKS;
  localparam int MEM_ADDR_WIDTH = `VX_CFG_PLATFORM_MEMORY_ADDR_WIDTH
                                  - $clog2(MEM_NUM_BANKS);
  localparam int MEM_TAG_WIDTH  = 64;

  logic clk = 0;
  logic reset = 1;
  always #5 clk = ~clk;   // 100 MHz

  initial begin
    repeat (`VX_CFG_RESET_DELAY) @(negedge clk);
    reset = 1'b0;
  end

  // ---- interfaces ----
  vx_ctrl_if ctrl_if (.clk(clk), .reset(reset));
  vx_dcr_if  #(.ADDR_WIDTH(12), .DATA_WIDTH(32))
             dcr_if  (.clk(clk), .reset(reset));
  vx_mem_if  #(.DATA_SIZE(DATA_SIZE), .ADDR_WIDTH(MEM_ADDR_WIDTH),
               .TAG_WIDTH(MEM_TAG_WIDTH))
             mem_if [MEM_NUM_BANKS] (.clk(clk), .reset(reset));

  // ---- DUT hookup (unpacked-array ports <-> per-bank interfaces) ----
  wire                        mem_req_valid  [MEM_NUM_BANKS];
  wire                        mem_req_rw     [MEM_NUM_BANKS];
  wire [DATA_SIZE-1:0]        mem_req_byteen [MEM_NUM_BANKS];
  wire [MEM_ADDR_WIDTH-1:0]   mem_req_addr   [MEM_NUM_BANKS];
  wire [MEM_DATA_WIDTH-1:0]   mem_req_data   [MEM_NUM_BANKS];
  wire [MEM_TAG_WIDTH-1:0]    mem_req_tag    [MEM_NUM_BANKS];
  logic                       mem_req_ready  [MEM_NUM_BANKS];
  logic                       mem_rsp_valid  [MEM_NUM_BANKS];
  logic [MEM_DATA_WIDTH-1:0]  mem_rsp_data   [MEM_NUM_BANKS];
  logic [MEM_TAG_WIDTH-1:0]   mem_rsp_tag    [MEM_NUM_BANKS];
  wire                        mem_rsp_ready  [MEM_NUM_BANKS];

  for (genvar b = 0; b < MEM_NUM_BANKS; b++) begin : g_mem_bind
    assign mem_if[b].req_valid  = mem_req_valid[b];
    assign mem_if[b].req_rw     = mem_req_rw[b];
    assign mem_if[b].req_byteen = mem_req_byteen[b];
    assign mem_if[b].req_addr   = mem_req_addr[b];
    assign mem_if[b].req_data   = mem_req_data[b];
    assign mem_if[b].req_tag    = mem_req_tag[b];
    always_comb mem_req_ready[b] = mem_if[b].req_ready;
    always_comb mem_rsp_valid[b] = mem_if[b].rsp_valid;
    always_comb mem_rsp_data[b]  = mem_if[b].rsp_data;
    always_comb mem_rsp_tag[b]   = mem_if[b].rsp_tag;
    assign mem_if[b].rsp_ready  = mem_rsp_ready[b];
  end

  rtlsim_shim dut (
    .clk            (clk),
    .reset          (reset),
    .mem_req_valid  (mem_req_valid),
    .mem_req_rw     (mem_req_rw),
    .mem_req_byteen (mem_req_byteen),
    .mem_req_addr   (mem_req_addr),
    .mem_req_data   (mem_req_data),
    .mem_req_tag    (mem_req_tag),
    .mem_req_ready  (mem_req_ready),
    .mem_rsp_valid  (mem_rsp_valid),
    .mem_rsp_data   (mem_rsp_data),
    .mem_rsp_tag    (mem_rsp_tag),
    .mem_rsp_ready  (mem_rsp_ready),
    .dcr_req_valid  (dcr_if.req_valid),
    .dcr_req_rw     (dcr_if.req_rw),
    .dcr_req_addr   (dcr_if.req_addr),
    .dcr_req_data   (dcr_if.req_data),
    .dcr_rsp_valid  (dcr_if.rsp_valid),
    .dcr_rsp_data   (dcr_if.rsp_data),
    .start          (ctrl_if.start),
    .busy           (ctrl_if.busy)
  );

  // ---- UVM config + run ----
  for (genvar b = 0; b < MEM_NUM_BANKS; b++) begin : g_vif_cfg
    initial uvm_config_db#(virtual vx_mem_if)::set(
      null, "uvm_test_top.env", $sformatf("mem_vif_%0d", b), mem_if[b]);
  end

  initial begin
    ctrl_if.start = 1'b0;
    uvm_config_db#(virtual vx_dcr_if)::set(
      null, "uvm_test_top.env.dcr_agent", "vif", dcr_if);
    uvm_config_db#(virtual vx_ctrl_if)::set(
      null, "uvm_test_top.env.ctrl_agent", "vif", ctrl_if);
    run_test();
  end

endmodule
