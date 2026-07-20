bind axi_slave_ooo_delay  axi_assertions axi_assertions_i (
  .axi_aclk    (axi_aclk),
  .axi_areset_n(axi_areset_n),

  .axi_awvalid (axi_awvalid),
  .axi_awready (axi_awready),
  .axi_awid    (axi_awid),
  .axi_awaddr  (axi_awaddr),
  .axi_awlen   (axi_awlen),
 // .axi_awsize  (axi_awsize),
  .axi_awburst (axi_awburst),

  .axi_wvalid  (axi_wvalid),
  .axi_wready  (axi_wready),
  .axi_wdata   (axi_wdata),
  .axi_wstrb   (axi_wstrb),
  .axi_wlast   (axi_wlast),

  .axi_bvalid  (axi_bvalid),
  .axi_bready  (axi_bready),
  .axi_bid     (axi_bid),
  .axi_bresp   (axi_bresp),

  .axi_arvalid (axi_arvalid),
  .axi_arready (axi_arready),
  .axi_arid    (axi_arid),
  .axi_araddr  (axi_araddr),
  .axi_arlen   (axi_arlen),
//  .axi_arsize  (axi_arsize),
  .axi_arburst (axi_arburst),

  .axi_rvalid  (axi_rvalid),
  .axi_rready  (axi_rready),
  .axi_rid     (axi_rid),
  .axi_rdata   (axi_rdata),
  .axi_rresp   (axi_rresp),
  .axi_rlast   (axi_rlast)
);
