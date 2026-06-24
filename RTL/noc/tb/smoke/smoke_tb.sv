// ============================================================================
//  smoke_tb.sv  —  directed datapath smoke test (non-UVM)
// ----------------------------------------------------------------------------
//  Drives one write+read from M0 to each legal target (S0, S1, P0, P1), an
//  unmapped access (expect DECERR), a 3-beat APB burst, and an APB PSLVERR
//  case (expect SLVERR).  M1 is held idle.  Behavioral BFMs respond.
//  Purpose: functionally validate the Phase-1 datapath before the UVM env.
//    run:  make smoke
// ============================================================================
`timescale 1ns/1ps
module smoke_tb;
  import noc_pkg::*;

  // ----------------------------- Clock / reset ------------------------------
  logic aclk = 0;
  logic aresetn = 0;
  always #5 aclk = ~aclk;
  initial begin
    aresetn = 1'b0;
    repeat (5) @(posedge aclk);
    aresetn = 1'b1;
  end

  int errors = 0;

  // global timeout so a DUT hang can't wedge the smoke test
  initial begin
    #50us;
    $display("SMOKE: TIMEOUT (possible DUT hang)");
    $finish;
  end

  // ----------------------------- Interfaces ---------------------------------
  axi_if #(.ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH), .STRB_WIDTH(STRB_WIDTH), .ID_WIDTH(ID_WIDTH))
         m0_if (.aclk(aclk), .aresetn(aresetn));
  axi_if #(.ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH), .STRB_WIDTH(STRB_WIDTH), .ID_WIDTH(ID_WIDTH))
         m1_if (.aclk(aclk), .aresetn(aresetn));
  axi_if #(.ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH), .STRB_WIDTH(STRB_WIDTH), .ID_WIDTH(SLV_ID_WIDTH))
         s0_if (.aclk(aclk), .aresetn(aresetn));
  axi_if #(.ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH), .STRB_WIDTH(STRB_WIDTH), .ID_WIDTH(SLV_ID_WIDTH))
         s1_if (.aclk(aclk), .aresetn(aresetn));
  apb_if #(.ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH), .STRB_WIDTH(STRB_WIDTH))
         p0_if (.pclk(aclk), .presetn(aresetn));
  apb_if #(.ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH), .STRB_WIDTH(STRB_WIDTH))
         p1_if (.pclk(aclk), .presetn(aresetn));

  // ----------------------------- DUT ----------------------------------------
  noc_top u_noc (
    .aclk(aclk), .aresetn(aresetn),
    .m0_awid(m0_if.awid), .m0_awaddr(m0_if.awaddr), .m0_awlen(m0_if.awlen), .m0_awsize(m0_if.awsize),
    .m0_awburst(m0_if.awburst), .m0_awlock(m0_if.awlock), .m0_awcache(m0_if.awcache), .m0_awprot(m0_if.awprot),
    .m0_awqos(m0_if.awqos), .m0_awvalid(m0_if.awvalid), .m0_awready(m0_if.awready),
    .m0_wdata(m0_if.wdata), .m0_wstrb(m0_if.wstrb), .m0_wlast(m0_if.wlast), .m0_wvalid(m0_if.wvalid), .m0_wready(m0_if.wready),
    .m0_bid(m0_if.bid), .m0_bresp(m0_if.bresp), .m0_bvalid(m0_if.bvalid), .m0_bready(m0_if.bready),
    .m0_arid(m0_if.arid), .m0_araddr(m0_if.araddr), .m0_arlen(m0_if.arlen), .m0_arsize(m0_if.arsize),
    .m0_arburst(m0_if.arburst), .m0_arlock(m0_if.arlock), .m0_arcache(m0_if.arcache), .m0_arprot(m0_if.arprot),
    .m0_arqos(m0_if.arqos), .m0_arvalid(m0_if.arvalid), .m0_arready(m0_if.arready),
    .m0_rid(m0_if.rid), .m0_rdata(m0_if.rdata), .m0_rresp(m0_if.rresp), .m0_rlast(m0_if.rlast), .m0_rvalid(m0_if.rvalid), .m0_rready(m0_if.rready),

    .m1_awid(m1_if.awid), .m1_awaddr(m1_if.awaddr), .m1_awlen(m1_if.awlen), .m1_awsize(m1_if.awsize),
    .m1_awburst(m1_if.awburst), .m1_awlock(m1_if.awlock), .m1_awcache(m1_if.awcache), .m1_awprot(m1_if.awprot),
    .m1_awqos(m1_if.awqos), .m1_awvalid(m1_if.awvalid), .m1_awready(m1_if.awready),
    .m1_wdata(m1_if.wdata), .m1_wstrb(m1_if.wstrb), .m1_wlast(m1_if.wlast), .m1_wvalid(m1_if.wvalid), .m1_wready(m1_if.wready),
    .m1_bid(m1_if.bid), .m1_bresp(m1_if.bresp), .m1_bvalid(m1_if.bvalid), .m1_bready(m1_if.bready),
    .m1_arid(m1_if.arid), .m1_araddr(m1_if.araddr), .m1_arlen(m1_if.arlen), .m1_arsize(m1_if.arsize),
    .m1_arburst(m1_if.arburst), .m1_arlock(m1_if.arlock), .m1_arcache(m1_if.arcache), .m1_arprot(m1_if.arprot),
    .m1_arqos(m1_if.arqos), .m1_arvalid(m1_if.arvalid), .m1_arready(m1_if.arready),
    .m1_rid(m1_if.rid), .m1_rdata(m1_if.rdata), .m1_rresp(m1_if.rresp), .m1_rlast(m1_if.rlast), .m1_rvalid(m1_if.rvalid), .m1_rready(m1_if.rready),

    .s0_awid(s0_if.awid), .s0_awaddr(s0_if.awaddr), .s0_awlen(s0_if.awlen), .s0_awsize(s0_if.awsize),
    .s0_awburst(s0_if.awburst), .s0_awlock(s0_if.awlock), .s0_awcache(s0_if.awcache), .s0_awprot(s0_if.awprot),
    .s0_awqos(s0_if.awqos), .s0_awvalid(s0_if.awvalid), .s0_awready(s0_if.awready),
    .s0_wdata(s0_if.wdata), .s0_wstrb(s0_if.wstrb), .s0_wlast(s0_if.wlast), .s0_wvalid(s0_if.wvalid), .s0_wready(s0_if.wready),
    .s0_bid(s0_if.bid), .s0_bresp(s0_if.bresp), .s0_bvalid(s0_if.bvalid), .s0_bready(s0_if.bready),
    .s0_arid(s0_if.arid), .s0_araddr(s0_if.araddr), .s0_arlen(s0_if.arlen), .s0_arsize(s0_if.arsize),
    .s0_arburst(s0_if.arburst), .s0_arlock(s0_if.arlock), .s0_arcache(s0_if.arcache), .s0_arprot(s0_if.arprot),
    .s0_arqos(s0_if.arqos), .s0_arvalid(s0_if.arvalid), .s0_arready(s0_if.arready),
    .s0_rid(s0_if.rid), .s0_rdata(s0_if.rdata), .s0_rresp(s0_if.rresp), .s0_rlast(s0_if.rlast), .s0_rvalid(s0_if.rvalid), .s0_rready(s0_if.rready),

    .s1_awid(s1_if.awid), .s1_awaddr(s1_if.awaddr), .s1_awlen(s1_if.awlen), .s1_awsize(s1_if.awsize),
    .s1_awburst(s1_if.awburst), .s1_awlock(s1_if.awlock), .s1_awcache(s1_if.awcache), .s1_awprot(s1_if.awprot),
    .s1_awqos(s1_if.awqos), .s1_awvalid(s1_if.awvalid), .s1_awready(s1_if.awready),
    .s1_wdata(s1_if.wdata), .s1_wstrb(s1_if.wstrb), .s1_wlast(s1_if.wlast), .s1_wvalid(s1_if.wvalid), .s1_wready(s1_if.wready),
    .s1_bid(s1_if.bid), .s1_bresp(s1_if.bresp), .s1_bvalid(s1_if.bvalid), .s1_bready(s1_if.bready),
    .s1_arid(s1_if.arid), .s1_araddr(s1_if.araddr), .s1_arlen(s1_if.arlen), .s1_arsize(s1_if.arsize),
    .s1_arburst(s1_if.arburst), .s1_arlock(s1_if.arlock), .s1_arcache(s1_if.arcache), .s1_arprot(s1_if.arprot),
    .s1_arqos(s1_if.arqos), .s1_arvalid(s1_if.arvalid), .s1_arready(s1_if.arready),
    .s1_rid(s1_if.rid), .s1_rdata(s1_if.rdata), .s1_rresp(s1_if.rresp), .s1_rlast(s1_if.rlast), .s1_rvalid(s1_if.rvalid), .s1_rready(s1_if.rready),

    .p0_paddr(p0_if.paddr), .p0_pprot(p0_if.pprot), .p0_psel(p0_if.psel), .p0_penable(p0_if.penable),
    .p0_pwrite(p0_if.pwrite), .p0_pwdata(p0_if.pwdata), .p0_pstrb(p0_if.pstrb),
    .p0_prdata(p0_if.prdata), .p0_pready(p0_if.pready), .p0_pslverr(p0_if.pslverr),
    .p1_paddr(p1_if.paddr), .p1_pprot(p1_if.pprot), .p1_psel(p1_if.psel), .p1_penable(p1_if.penable),
    .p1_pwrite(p1_if.pwrite), .p1_pwdata(p1_if.pwdata), .p1_pstrb(p1_if.pstrb),
    .p1_prdata(p1_if.prdata), .p1_pready(p1_if.pready), .p1_pslverr(p1_if.pslverr)
  );

  // ----------------------------- Responders ---------------------------------
  axi_slave_bfm              u_s0 (.s(s0_if));
  axi_slave_bfm #(.RD_LAT(8)) u_s1 (.s(s1_if));   // S1 is slow -> enables OOO demo
  apb_slave_bfm u_p0 (.p(p0_if));
  apb_slave_bfm u_p1 (.p(p1_if));

  // M1 held idle
  assign m1_if.awvalid = 1'b0; assign m1_if.wvalid = 1'b0; assign m1_if.arvalid = 1'b0;
  assign m1_if.bready  = 1'b1; assign m1_if.rready = 1'b1;
  assign m1_if.awid='0; assign m1_if.awaddr='0; assign m1_if.awlen='0; assign m1_if.awsize='0;
  assign m1_if.awburst='0; assign m1_if.awlock='0; assign m1_if.awcache='0; assign m1_if.awprot='0; assign m1_if.awqos='0;
  assign m1_if.wdata='0; assign m1_if.wstrb='0; assign m1_if.wlast='0;
  assign m1_if.arid='0; assign m1_if.araddr='0; assign m1_if.arlen='0; assign m1_if.arsize='0;
  assign m1_if.arburst='0; assign m1_if.arlock='0; assign m1_if.arcache='0; assign m1_if.arprot='0; assign m1_if.arqos='0;

  // ----------------------------- M0 driver tasks ----------------------------
  task automatic do_write(input logic [ID_WIDTH-1:0] id, input logic [31:0] addr,
                          input logic [7:0] len, input logic [2:0] size,
                          input logic [31:0] d0, output logic [1:0] resp);
    @(posedge aclk);
    m0_if.awid<=id; m0_if.awaddr<=addr; m0_if.awlen<=len; m0_if.awsize<=size;
    m0_if.awburst<=AXI_BURST_INCR; m0_if.awvalid<=1'b1;
    @(posedge aclk); while (!m0_if.awready) @(posedge aclk);
    m0_if.awvalid<=1'b0;
    for (int i=0;i<=len;i++) begin
      m0_if.wdata<=d0+i; m0_if.wstrb<=4'hF; m0_if.wlast<=(i==len); m0_if.wvalid<=1'b1;
      @(posedge aclk); while (!m0_if.wready) @(posedge aclk);
      m0_if.wvalid<=1'b0; m0_if.wlast<=1'b0;
    end
    m0_if.bready<=1'b1;
    @(posedge aclk); while (!m0_if.bvalid) @(posedge aclk);
    resp = m0_if.bresp;
    m0_if.bready<=1'b0;
  endtask

  task automatic do_read(input logic [ID_WIDTH-1:0] id, input logic [31:0] addr,
                         input logic [7:0] len, input logic [2:0] size,
                         output logic [1:0] resp, output logic [31:0] d0);
    @(posedge aclk);
    m0_if.arid<=id; m0_if.araddr<=addr; m0_if.arlen<=len; m0_if.arsize<=size;
    m0_if.arburst<=AXI_BURST_INCR; m0_if.arvalid<=1'b1;
    @(posedge aclk); while (!m0_if.arready) @(posedge aclk);
    m0_if.arvalid<=1'b0;
    m0_if.rready<=1'b1;
    resp = AXI_RESP_OKAY; d0 = '0;
    for (int i=0;i<=len;i++) begin
      @(posedge aclk); while (!m0_if.rvalid) @(posedge aclk);
      if (i==0)        d0   = m0_if.rdata;
      resp = m0_if.rresp;             // keep last beat's response
    end
    m0_if.rready<=1'b0;
  endtask

  // ----------------------------- Checks -------------------------------------
  task automatic check_wr_rd(string name, logic [31:0] addr);
    logic [1:0] wresp, rresp; logic [31:0] rdata; logic [31:0] wdata;
    wdata = 32'hA5A50000 + addr[15:0];
    do_write(4'h1, addr, 8'd0, 3'd2, wdata, wresp);
    do_read (4'h1, addr, 8'd0, 3'd2, rresp, rdata);
    if (wresp!==AXI_RESP_OKAY) begin errors++; $display("  [%0s] WRITE resp exp OKAY got %0d", name, wresp); end
    if (rresp!==AXI_RESP_OKAY) begin errors++; $display("  [%0s] READ  resp exp OKAY got %0d", name, rresp); end
    if (rdata!==wdata)         begin errors++; $display("  [%0s] DATA  exp %h got %h", name, wdata, rdata); end
    if (wresp===AXI_RESP_OKAY && rresp===AXI_RESP_OKAY && rdata===wdata)
      $display("  [%0s] OK   addr=%h data=%h", name, addr, rdata);
  endtask

  task automatic check_decerr(logic [31:0] addr);
    logic [1:0] wresp, rresp; logic [31:0] rdata;
    do_write(4'h2, addr, 8'd0, 3'd2, 32'hDEAD_BEEF, wresp);
    do_read (4'h2, addr, 8'd0, 3'd2, rresp, rdata);
    if (wresp!==AXI_RESP_DECERR) begin errors++; $display("  [DECERR %h] WRITE exp DECERR got %0d", addr, wresp); end
    if (rresp!==AXI_RESP_DECERR) begin errors++; $display("  [DECERR %h] READ  exp DECERR got %0d", addr, rresp); end
    if (wresp===AXI_RESP_DECERR && rresp===AXI_RESP_DECERR) $display("  [DECERR %h] OK", addr);
  endtask

  task automatic check_burst_p0();
    logic [1:0] wresp, rresp; logic [31:0] rd0;
    do_write(4'h3, 32'h2000_0040, 8'd2, 3'd2, 32'h1111_0000, wresp);  // 3-beat INCR
    do_read (4'h3, 32'h2000_0040, 8'd2, 3'd2, rresp, rd0);
    if (wresp!==AXI_RESP_OKAY) begin errors++; $display("  [P0-burst] WRITE resp exp OKAY got %0d", wresp); end
    if (rd0!==32'h1111_0000)   begin errors++; $display("  [P0-burst] beat0 exp 11110000 got %h", rd0); end
    if (wresp===AXI_RESP_OKAY && rd0===32'h1111_0000) $display("  [P0-burst] OK");
  endtask

  task automatic check_apb_err();
    logic [1:0] wresp, rresp; logic [31:0] rd;
    do_write(4'h4, 32'h2000_00E0, 8'd0, 3'd2, 32'hBADC_0DE0, wresp);  // magic PSLVERR offset
    do_read (4'h4, 32'h2000_00E0, 8'd0, 3'd2, rresp, rd);
    if (wresp!==AXI_RESP_SLVERR) begin errors++; $display("  [APB-err] WRITE exp SLVERR got %0d", wresp); end
    if (rresp!==AXI_RESP_SLVERR) begin errors++; $display("  [APB-err] READ  exp SLVERR got %0d", rresp); end
    if (wresp===AXI_RESP_SLVERR && rresp===AXI_RESP_SLVERR) $display("  [APB-err] OK");
  endtask

  // Concurrent cross-target reads: id=1 -> slow S1, id=2 -> fast S0.
  // With multi-outstanding reads, id=2 must return BEFORE id=1 (out of order).
  task automatic check_ooo();
    logic [3:0]  id_order [$];
    logic [31:0] d1, d2;
    int got;
    got = 0; d1 = 'x; d2 = 'x;
    // issue AR id=1 -> S1 (slow), addr previously written = a5a50200
    @(posedge aclk);
    m0_if.arid<=4'd1; m0_if.araddr<=32'h1000_0200; m0_if.arlen<=8'd0; m0_if.arsize<=3'd2;
    m0_if.arburst<=AXI_BURST_INCR; m0_if.arvalid<=1'b1;
    @(posedge aclk); while(!m0_if.arready) @(posedge aclk);
    m0_if.arvalid<=1'b0;
    // issue AR id=2 -> S0 (fast), addr previously written = a5a50100
    @(posedge aclk);
    m0_if.arid<=4'd2; m0_if.araddr<=32'h0000_0100; m0_if.arlen<=8'd0; m0_if.arsize<=3'd2;
    m0_if.arburst<=AXI_BURST_INCR; m0_if.arvalid<=1'b1;
    @(posedge aclk); while(!m0_if.arready) @(posedge aclk);
    m0_if.arvalid<=1'b0;
    // collect both responses, recording arrival order by id
    m0_if.rready<=1'b1;
    while (got < 2) begin
      @(posedge aclk);
      if (m0_if.rvalid && m0_if.rlast) begin
        id_order.push_back(m0_if.rid);
        if (m0_if.rid==4'd1) d1=m0_if.rdata; else d2=m0_if.rdata;
        got++;
      end
    end
    m0_if.rready<=1'b0;
    if (id_order[0] !== 4'd2) begin errors++; $display("  [OOO] FAIL first id=%0d (expected 2 / S0 fast)", id_order[0]); end
    if (d2 !== 32'ha5a50100) begin errors++; $display("  [OOO] FAIL S0 data exp a5a50100 got %h", d2); end
    if (d1 !== 32'ha5a50200) begin errors++; $display("  [OOO] FAIL S1 data exp a5a50200 got %h", d1); end
    if (id_order[0]===4'd2 && d2===32'ha5a50100 && d1===32'ha5a50200)
      $display("  [OOO] OK   id=2 (S0 fast) returned before id=1 (S1 slow); data correct");
  endtask

  // ----------------------------- Stimulus -----------------------------------
  initial begin
    m0_if.awvalid=1'b0; m0_if.wvalid=1'b0; m0_if.arvalid=1'b0; m0_if.bready=1'b0; m0_if.rready=1'b0;
    m0_if.awlock=1'b0; m0_if.awcache='0; m0_if.awprot='0; m0_if.awqos='0; m0_if.awburst=AXI_BURST_INCR;
    m0_if.arlock=1'b0; m0_if.arcache='0; m0_if.arprot='0; m0_if.arqos='0; m0_if.arburst=AXI_BURST_INCR;
    m0_if.wstrb='0; m0_if.wlast=1'b0;
    @(posedge aresetn);
    repeat (3) @(posedge aclk);

    $display("==== NoC datapath smoke ====");
    check_wr_rd("S0", 32'h0000_0100);
    check_wr_rd("S1", 32'h1000_0200);
    check_wr_rd("P0", 32'h2000_0000);
    check_wr_rd("P1", 32'h2001_0000);
    check_decerr (32'h3000_0000);
    check_burst_p0();
    check_apb_err();
    check_ooo();

    repeat (5) @(posedge aclk);
    if (errors == 0) $display("SMOKE: PASS (all datapath checks OK)");
    else             $display("SMOKE: FAIL (%0d errors)", errors);
    $finish;
  end

endmodule : smoke_tb
