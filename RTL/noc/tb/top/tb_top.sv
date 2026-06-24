// ============================================================================
//  tb_top.sv  —  NoC testbench top
// ----------------------------------------------------------------------------
//  Clock/reset, six interface instances (2 master AXI @ID=4, 2 slave AXI
//  @ID=5, 2 APB), the DUT, config_db publication of the vifs, a global
//  watchdog (so a DUT hang ends as UVM_ERROR not a frozen sim), and waves.
// ============================================================================
`timescale 1ns/1ps
module tb_top;
  import uvm_pkg::*;
  `include "uvm_macros.svh"
  import noc_pkg::*;
  import noc_tb_pkg::*;

  // ----------------------------- Clock / reset ------------------------------
  logic aclk = 0;
  logic aresetn = 0;
  always #5 aclk = ~aclk;            // 100 MHz

  initial begin
    aresetn = 1'b0;
    repeat (5) @(posedge aclk);
    aresetn = 1'b1;
  end

  // ----------------------------- Interfaces ---------------------------------
  axi_if #(.ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH),
           .STRB_WIDTH(STRB_WIDTH), .ID_WIDTH(ID_WIDTH))
         m0_if (.aclk(aclk), .aresetn(aresetn));
  axi_if #(.ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH),
           .STRB_WIDTH(STRB_WIDTH), .ID_WIDTH(ID_WIDTH))
         m1_if (.aclk(aclk), .aresetn(aresetn));
  axi_if #(.ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH),
           .STRB_WIDTH(STRB_WIDTH), .ID_WIDTH(SLV_ID_WIDTH))
         s0_if (.aclk(aclk), .aresetn(aresetn));
  axi_if #(.ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH),
           .STRB_WIDTH(STRB_WIDTH), .ID_WIDTH(SLV_ID_WIDTH))
         s1_if (.aclk(aclk), .aresetn(aresetn));
  apb_if #(.ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH), .STRB_WIDTH(STRB_WIDTH))
         p0_if (.pclk(aclk), .presetn(aresetn));
  apb_if #(.ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH), .STRB_WIDTH(STRB_WIDTH))
         p1_if (.pclk(aclk), .presetn(aresetn));

  // ----------------------------- DUT ----------------------------------------
  noc_top u_noc (
    .aclk      (aclk),
    .aresetn   (aresetn),

    // ---- Master 0 ----
    .m0_awid(m0_if.awid), .m0_awaddr(m0_if.awaddr), .m0_awlen(m0_if.awlen),
    .m0_awsize(m0_if.awsize), .m0_awburst(m0_if.awburst), .m0_awlock(m0_if.awlock),
    .m0_awcache(m0_if.awcache), .m0_awprot(m0_if.awprot), .m0_awqos(m0_if.awqos),
    .m0_awvalid(m0_if.awvalid), .m0_awready(m0_if.awready),
    .m0_wdata(m0_if.wdata), .m0_wstrb(m0_if.wstrb), .m0_wlast(m0_if.wlast),
    .m0_wvalid(m0_if.wvalid), .m0_wready(m0_if.wready),
    .m0_bid(m0_if.bid), .m0_bresp(m0_if.bresp), .m0_bvalid(m0_if.bvalid), .m0_bready(m0_if.bready),
    .m0_arid(m0_if.arid), .m0_araddr(m0_if.araddr), .m0_arlen(m0_if.arlen),
    .m0_arsize(m0_if.arsize), .m0_arburst(m0_if.arburst), .m0_arlock(m0_if.arlock),
    .m0_arcache(m0_if.arcache), .m0_arprot(m0_if.arprot), .m0_arqos(m0_if.arqos),
    .m0_arvalid(m0_if.arvalid), .m0_arready(m0_if.arready),
    .m0_rid(m0_if.rid), .m0_rdata(m0_if.rdata), .m0_rresp(m0_if.rresp),
    .m0_rlast(m0_if.rlast), .m0_rvalid(m0_if.rvalid), .m0_rready(m0_if.rready),

    // ---- Master 1 ----
    .m1_awid(m1_if.awid), .m1_awaddr(m1_if.awaddr), .m1_awlen(m1_if.awlen),
    .m1_awsize(m1_if.awsize), .m1_awburst(m1_if.awburst), .m1_awlock(m1_if.awlock),
    .m1_awcache(m1_if.awcache), .m1_awprot(m1_if.awprot), .m1_awqos(m1_if.awqos),
    .m1_awvalid(m1_if.awvalid), .m1_awready(m1_if.awready),
    .m1_wdata(m1_if.wdata), .m1_wstrb(m1_if.wstrb), .m1_wlast(m1_if.wlast),
    .m1_wvalid(m1_if.wvalid), .m1_wready(m1_if.wready),
    .m1_bid(m1_if.bid), .m1_bresp(m1_if.bresp), .m1_bvalid(m1_if.bvalid), .m1_bready(m1_if.bready),
    .m1_arid(m1_if.arid), .m1_araddr(m1_if.araddr), .m1_arlen(m1_if.arlen),
    .m1_arsize(m1_if.arsize), .m1_arburst(m1_if.arburst), .m1_arlock(m1_if.arlock),
    .m1_arcache(m1_if.arcache), .m1_arprot(m1_if.arprot), .m1_arqos(m1_if.arqos),
    .m1_arvalid(m1_if.arvalid), .m1_arready(m1_if.arready),
    .m1_rid(m1_if.rid), .m1_rdata(m1_if.rdata), .m1_rresp(m1_if.rresp),
    .m1_rlast(m1_if.rlast), .m1_rvalid(m1_if.rvalid), .m1_rready(m1_if.rready),

    // ---- AXI Slave 0 ----
    .s0_awid(s0_if.awid), .s0_awaddr(s0_if.awaddr), .s0_awlen(s0_if.awlen),
    .s0_awsize(s0_if.awsize), .s0_awburst(s0_if.awburst), .s0_awlock(s0_if.awlock),
    .s0_awcache(s0_if.awcache), .s0_awprot(s0_if.awprot), .s0_awqos(s0_if.awqos),
    .s0_awvalid(s0_if.awvalid), .s0_awready(s0_if.awready),
    .s0_wdata(s0_if.wdata), .s0_wstrb(s0_if.wstrb), .s0_wlast(s0_if.wlast),
    .s0_wvalid(s0_if.wvalid), .s0_wready(s0_if.wready),
    .s0_bid(s0_if.bid), .s0_bresp(s0_if.bresp), .s0_bvalid(s0_if.bvalid), .s0_bready(s0_if.bready),
    .s0_arid(s0_if.arid), .s0_araddr(s0_if.araddr), .s0_arlen(s0_if.arlen),
    .s0_arsize(s0_if.arsize), .s0_arburst(s0_if.arburst), .s0_arlock(s0_if.arlock),
    .s0_arcache(s0_if.arcache), .s0_arprot(s0_if.arprot), .s0_arqos(s0_if.arqos),
    .s0_arvalid(s0_if.arvalid), .s0_arready(s0_if.arready),
    .s0_rid(s0_if.rid), .s0_rdata(s0_if.rdata), .s0_rresp(s0_if.rresp),
    .s0_rlast(s0_if.rlast), .s0_rvalid(s0_if.rvalid), .s0_rready(s0_if.rready),

    // ---- AXI Slave 1 ----
    .s1_awid(s1_if.awid), .s1_awaddr(s1_if.awaddr), .s1_awlen(s1_if.awlen),
    .s1_awsize(s1_if.awsize), .s1_awburst(s1_if.awburst), .s1_awlock(s1_if.awlock),
    .s1_awcache(s1_if.awcache), .s1_awprot(s1_if.awprot), .s1_awqos(s1_if.awqos),
    .s1_awvalid(s1_if.awvalid), .s1_awready(s1_if.awready),
    .s1_wdata(s1_if.wdata), .s1_wstrb(s1_if.wstrb), .s1_wlast(s1_if.wlast),
    .s1_wvalid(s1_if.wvalid), .s1_wready(s1_if.wready),
    .s1_bid(s1_if.bid), .s1_bresp(s1_if.bresp), .s1_bvalid(s1_if.bvalid), .s1_bready(s1_if.bready),
    .s1_arid(s1_if.arid), .s1_araddr(s1_if.araddr), .s1_arlen(s1_if.arlen),
    .s1_arsize(s1_if.arsize), .s1_arburst(s1_if.arburst), .s1_arlock(s1_if.arlock),
    .s1_arcache(s1_if.arcache), .s1_arprot(s1_if.arprot), .s1_arqos(s1_if.arqos),
    .s1_arvalid(s1_if.arvalid), .s1_arready(s1_if.arready),
    .s1_rid(s1_if.rid), .s1_rdata(s1_if.rdata), .s1_rresp(s1_if.rresp),
    .s1_rlast(s1_if.rlast), .s1_rvalid(s1_if.rvalid), .s1_rready(s1_if.rready),

    // ---- APB Slave 0 ----
    .p0_paddr(p0_if.paddr), .p0_pprot(p0_if.pprot), .p0_psel(p0_if.psel),
    .p0_penable(p0_if.penable), .p0_pwrite(p0_if.pwrite), .p0_pwdata(p0_if.pwdata),
    .p0_pstrb(p0_if.pstrb), .p0_prdata(p0_if.prdata), .p0_pready(p0_if.pready),
    .p0_pslverr(p0_if.pslverr),

    // ---- APB Slave 1 ----
    .p1_paddr(p1_if.paddr), .p1_pprot(p1_if.pprot), .p1_psel(p1_if.psel),
    .p1_penable(p1_if.penable), .p1_pwrite(p1_if.pwrite), .p1_pwdata(p1_if.pwdata),
    .p1_pstrb(p1_if.pstrb), .p1_prdata(p1_if.prdata), .p1_pready(p1_if.pready),
    .p1_pslverr(p1_if.pslverr)
  );

  // ----------------------------- config_db ----------------------------------
  initial begin
    uvm_config_db#(virtual axi_if#(ADDR_WIDTH,DATA_WIDTH,STRB_WIDTH,ID_WIDTH))::set(null,"*","m0_vif", m0_if);
    uvm_config_db#(virtual axi_if#(ADDR_WIDTH,DATA_WIDTH,STRB_WIDTH,ID_WIDTH))::set(null,"*","m1_vif", m1_if);
    uvm_config_db#(virtual axi_if#(ADDR_WIDTH,DATA_WIDTH,STRB_WIDTH,SLV_ID_WIDTH))::set(null,"*","s0_vif", s0_if);
    uvm_config_db#(virtual axi_if#(ADDR_WIDTH,DATA_WIDTH,STRB_WIDTH,SLV_ID_WIDTH))::set(null,"*","s1_vif", s1_if);
    uvm_config_db#(virtual apb_if#(ADDR_WIDTH,DATA_WIDTH,STRB_WIDTH))::set(null,"*","p0_vif", p0_if);
    uvm_config_db#(virtual apb_if#(ADDR_WIDTH,DATA_WIDTH,STRB_WIDTH))::set(null,"*","p1_vif", p1_if);
    run_test();
  end

  // ----------------------------- Watchdog -----------------------------------
  initial begin
    int unsigned timeout_ns;
    timeout_ns = 500000;                      // 500 us default
    void'($value$plusargs("TIMEOUT_NS=%d", timeout_ns));
    #(timeout_ns * 1ns);
    `uvm_error("WDOG", $sformatf("Global timeout after %0d ns -- possible DUT hang/deadlock", timeout_ns))
    $finish;
  end

  // ----------------------------- Waves --------------------------------------
  initial begin
    if ($test$plusargs("DUMP_WAVES")) begin
      $shm_open("waves.shm");
      $shm_probe("ACTMF");
      `uvm_info("WAVES", "Dumping waves to waves.shm", UVM_NONE)
    end
  end

endmodule : tb_top
