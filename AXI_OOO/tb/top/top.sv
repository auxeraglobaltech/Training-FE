`timescale 1ns/1ps
module top;
  import uvm_pkg::*;
  import pkg::*;
 `include "uvm_macros.svh"
  initial vif.axi_aclk=0;
  always #5 vif.axi_aclk=~vif.axi_aclk;
 /* initial begin
    vif.axi_areset_n = 0;
    #5; 
   vif.axi_areset_n = 1;
  end8*/
  initial begin

  vif.axi_areset_n = 0;

  vif.axi_awvalid = 0;
  vif.axi_wvalid  = 0;
  vif.axi_bready  = 0;
  vif.axi_arvalid = 0;
  vif.axi_rready  = 0;
  vif.axi_wlast   = 0;

  repeat(5) @(posedge vif.axi_aclk);

  vif.axi_areset_n = 1;

end
  axiif vif();
   initial begin
  uvm_config_db#(virtual axiif)::set(null,"*","vif",vif);
  end
  axi_slave_ooo_delay DUT(
                 .axi_aclk	    (vif.axi_aclk),
                 .slave_wren   (vif.slave_wren),
	             .slave_waddr  (vif.slave_waddr),
		         .slave_wdata   (vif.slave_wdata),
		         .slave_rden   (vif.slave_rden),
		         .slave_raddr  (vif.slave_raddr),
                 .slave_rdata  (vif.slave_rdata),
		         .axi_areset_n  (vif.axi_areset_n),
	             .axi_awready   (vif.axi_awready),
	             .axi_wready    (vif.axi_wready),
	             .axi_bresp     (vif.axi_bresp),
	             .axi_bvalid    (vif.axi_bvalid),
	 	         .axi_bid       (vif.axi_bid),
	             .axi_arready   (vif.axi_arready),
	             .axi_rvalid    (vif.axi_rvalid),
 	             .axi_rid       (vif.axi_rid),
	             .axi_rlast     (vif.axi_rlast),
	 	         .axi_rresp     (vif.axi_rresp),
	             .axi_rdata     (vif.axi_rdata),
                 .axi_awaddr    (vif.axi_awaddr),
				 .axi_awvalid   (vif.axi_awvalid),
	 			 .axi_awid      (vif.axi_awid),
	 			 .axi_awlen     (vif.axi_awlen),
	 			 .axi_awburst 	(vif.axi_awburst),
	 	         .axi_wdata     (vif.axi_wdata),
				 .axi_wvalid    (vif.axi_wvalid),
	 		     .axi_wid       (vif.axi_wid),
				 .axi_wlast     (vif.axi_wlast),
	             .axi_wstrb     (vif.axi_wstrb),
				 .axi_bready    (vif.axi_bready),
	             .axi_araddr    (vif.axi_araddr),
				 .axi_arvalid   (vif.axi_arvalid),
	 			 .axi_arid      (vif.axi_arid),
	 			 .axi_arlen     (vif.axi_arlen),
	 		     .axi_arburst   (vif.axi_arburst),
				 .axi_rready    (vif.axi_rready)                 
                );

    initial begin
  run_test("");
  end
  initial begin
    $shm_open("wave.shm");
    $shm_probe("ACTMF");
  end

 /*property p_awvalid_hold;
    @(posedge vif.axi_aclk)
  disable iff (!vif.axi_areset_n)
   vif.axi_awvalid && !vif.axi_awready |=> vif.axi_awvalid;
  endproperty
  assert property (p_awvalid_hold)
    $display("assertion passed");
    else $error("AXI ASSERTION: AWVALID dropped before AWREADY");
 property p_aw_payload_stable;
   @(posedge vif.axi_aclk)
  disable iff (!vif.axi_areset_n)

    vif.axi_awvalid && !vif.axi_awready
    |=> $stable({
          vif.axi_awid,
          vif.axi_awaddr,
          vif.axi_awlen,
          vif.axi_awburst
        });
  endproperty
   assert property (p_aw_payload_stable)
   $display("assertion passed");
    else $error("AXI ASSERTION: AW payload changed while stalled");*/
axi_assertions axi_assertions_i (
    .axi_aclk    (vif.axi_aclk),
    .axi_areset_n(vif.axi_areset_n),

    .axi_awvalid (vif.axi_awvalid),
    .axi_awready (vif.axi_awready),
    .axi_awid    (vif.axi_awid),
    .axi_awaddr  (vif.axi_awaddr),
    .axi_awlen   (vif.axi_awlen),
    //.axi_awsize  (vif.axi_awsize),
    .axi_awburst (vif.axi_awburst),

    .axi_wvalid  (vif.axi_wvalid),
    .axi_wready  (vif.axi_wready),
    .axi_wdata   (vif.axi_wdata),
    .axi_wstrb   (vif.axi_wstrb),
    .axi_wlast   (vif.axi_wlast),

    .axi_bvalid  (vif.axi_bvalid),
    .axi_bready  (vif.axi_bready),
    .axi_bid     (vif.axi_bid),
    .axi_bresp   (vif.axi_bresp),

    .axi_arvalid (vif.axi_arvalid),
    .axi_arready (vif.axi_arready),
    .axi_arid    (vif.axi_arid),
    .axi_araddr  (vif.axi_araddr),
    .axi_arlen   (vif.axi_arlen),
   // .axi_arsize  (vif.axi_arsize),
    .axi_arburst (vif.axi_arburst),

    .axi_rvalid  (vif.axi_rvalid),
    .axi_rready  (vif.axi_rready),
    .axi_rid     (vif.axi_rid),
    .axi_rdata   (vif.axi_rdata),
    .axi_rresp   (vif.axi_rresp),
    .axi_rlast   (vif.axi_rlast)
  );
  


endmodule

