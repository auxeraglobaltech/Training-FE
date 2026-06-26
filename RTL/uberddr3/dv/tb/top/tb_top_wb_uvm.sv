// ============================================================================
//  tb_top_wb_uvm.sv  —  UVM top for the UberDDR3 Wishbone environment
// ----------------------------------------------------------------------------
//  Clocks/reset, the wb_if interface, ddr3_top (BIST off) wired to the
//  interface, the Micron x16 model, vif publication, a global watchdog, and
//  run_test(). The interface's calib_complete is driven by o_calib_complete.
// ============================================================================
`timescale 1ps/1ps
module tb_top_wb_uvm;
  import uvm_pkg::*;
  `include "uvm_macros.svh"
  import ddr_tb_pkg::*;

  localparam CONTROLLER_CLK_PERIOD = 10_000;
  localparam DDR3_CLK_PERIOD       = 2_500;
  localparam ROW_BITS=14, COL_BITS=10, BA_BITS=3, BYTE_LANES=2, DQ_BITS=8, AUX_WIDTH=16, serdes_ratio=4;
  localparam WB_DATA_BITS = DQ_BITS*BYTE_LANES*serdes_ratio*2;            // 128
  localparam WB_SEL_BITS  = WB_DATA_BITS/8;                               // 16
  localparam WB_ADDR_BITS = ROW_BITS+COL_BITS+BA_BITS-$clog2(serdes_ratio*2); // 24

  // ---- clocks / reset ----
  reg i_controller_clk, i_ddr3_clk, i_ref_clk, i_ddr3_clk_90, i_rst_n;
  initial begin i_controller_clk=1; i_ddr3_clk=1; i_ref_clk=1; i_ddr3_clk_90=1; end
  always #(CONTROLLER_CLK_PERIOD/2) i_controller_clk = ~i_controller_clk;
  always #(DDR3_CLK_PERIOD/2)       i_ddr3_clk       = ~i_ddr3_clk;
  always #2500                      i_ref_clk        = ~i_ref_clk;
  initial begin #(DDR3_CLK_PERIOD/4); forever #(DDR3_CLK_PERIOD/2) i_ddr3_clk_90 = ~i_ddr3_clk_90; end
  initial begin i_rst_n=0; #1_000_000; i_rst_n=1; end

  // ---- interface ----
  wb_if #(.ADDR_BITS(WB_ADDR_BITS), .DATA_BITS(WB_DATA_BITS),
          .SEL_BITS(WB_SEL_BITS), .AUX_WIDTH(AUX_WIDTH))
        wbif (.clk(i_controller_clk), .rst_n(i_rst_n));

  // ---- DDR3 pins ----
  wire o_ddr3_clk_p, o_ddr3_clk_n, o_ddr3_reset_n, o_ddr3_cke, o_ddr3_cs_n;
  wire o_ddr3_ras_n, o_ddr3_cas_n, o_ddr3_we_n, o_ddr3_odt;
  wire [ROW_BITS-1:0]           o_ddr3_addr;
  wire [BA_BITS-1:0]            o_ddr3_ba_addr;
  wire [DQ_BITS*BYTE_LANES-1:0] io_ddr3_dq;
  wire [BYTE_LANES-1:0]         io_ddr3_dqs, io_ddr3_dqs_n, o_ddr3_dm;
  wire [31:0] o_debug1; wire uart_tx;

  // ---- DUT ----
  ddr3_top #(
    .CONTROLLER_CLK_PERIOD(CONTROLLER_CLK_PERIOD), .DDR3_CLK_PERIOD(DDR3_CLK_PERIOD),
    .ROW_BITS(ROW_BITS), .COL_BITS(COL_BITS), .BA_BITS(BA_BITS), .BYTE_LANES(BYTE_LANES),
    .AUX_WIDTH(AUX_WIDTH), .MICRON_SIM(1), .ODELAY_SUPPORTED(0), .SECOND_WISHBONE(0),
    .WB_ERROR(0), .BIST_MODE(0), .ECC_ENABLE(0), .SELF_REFRESH(2'b00), .DUAL_RANK_DIMM(0), .DLL_OFF(0)
  ) dut (
    .i_controller_clk(i_controller_clk), .i_ddr3_clk(i_ddr3_clk), .i_ref_clk(i_ref_clk),
    .i_ddr3_clk_90(i_ddr3_clk_90), .i_rst_n(i_rst_n),
    .i_wb_cyc(wbif.wb_cyc), .i_wb_stb(wbif.wb_stb), .i_wb_we(wbif.wb_we), .i_wb_addr(wbif.wb_addr),
    .i_wb_data(wbif.wb_data), .i_wb_sel(wbif.wb_sel), .i_aux(wbif.aux),
    .o_wb_stall(wbif.wb_stall), .o_wb_ack(wbif.wb_ack), .o_wb_err(wbif.wb_err),
    .o_wb_data(wbif.wb_rdata), .o_aux(wbif.o_aux),
    .i_wb2_cyc(1'b0), .i_wb2_stb(1'b0), .i_wb2_we(1'b0), .i_wb2_addr('0),
    .i_wb2_data('0), .i_wb2_sel('0), .o_wb2_stall(), .o_wb2_ack(), .o_wb2_data(),
    .o_ddr3_clk_p(o_ddr3_clk_p), .o_ddr3_clk_n(o_ddr3_clk_n), .o_ddr3_reset_n(o_ddr3_reset_n),
    .o_ddr3_cke(o_ddr3_cke), .o_ddr3_cs_n(o_ddr3_cs_n), .o_ddr3_ras_n(o_ddr3_ras_n),
    .o_ddr3_cas_n(o_ddr3_cas_n), .o_ddr3_we_n(o_ddr3_we_n), .o_ddr3_addr(o_ddr3_addr),
    .o_ddr3_ba_addr(o_ddr3_ba_addr), .io_ddr3_dq(io_ddr3_dq), .io_ddr3_dqs(io_ddr3_dqs),
    .io_ddr3_dqs_n(io_ddr3_dqs_n), .o_ddr3_dm(o_ddr3_dm), .o_ddr3_odt(o_ddr3_odt),
    .o_calib_complete(wbif.calib_complete), .o_debug1(o_debug1),
    .i_user_self_refresh(1'b0), .uart_tx(uart_tx)
  );

  // ---- Micron x16 DDR3 model ----
  ddr3 #(.DLL_OFF(0)) ddr3_0 (
    .rst_n(o_ddr3_reset_n), .ck(o_ddr3_clk_p), .ck_n(o_ddr3_clk_n), .cke(o_ddr3_cke),
    .cs_n(o_ddr3_cs_n), .ras_n(o_ddr3_ras_n), .cas_n(o_ddr3_cas_n), .we_n(o_ddr3_we_n),
    .dm_tdqs(o_ddr3_dm), .ba(o_ddr3_ba_addr), .addr({2'b0, o_ddr3_addr}), .dq(io_ddr3_dq),
    .dqs(io_ddr3_dqs), .dqs_n(io_ddr3_dqs_n), .tdqs_n(), .odt(o_ddr3_odt)
  );

  // ---- config_db + run ----
  initial begin
    uvm_config_db#(virtual wb_if)::set(null, "*", "vif", wbif);
    run_test();
  end

  // ---- watchdog ----
  initial begin
    int unsigned timeout_ns; timeout_ns = 1_000_000;       // 1 ms default
    void'($value$plusargs("TIMEOUT_NS=%d", timeout_ns));
    #(timeout_ns * 1000);
    `uvm_error("WDOG", $sformatf("global timeout after %0d ns", timeout_ns))
    $finish;
  end

endmodule : tb_top_wb_uvm
