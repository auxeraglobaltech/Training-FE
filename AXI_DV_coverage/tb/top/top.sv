`timescale 1ns/1ps
module top;
  import uvm_pkg::*;
  import pkg::*;
 `include "uvm_macros.svh"
  initial vif.axi_aclk=0;
  always #5 vif.axi_aclk=~vif.axi_aclk;
  initial begin
    vif.axi_areset_n = 0;
    #5; 
   vif.axi_areset_n = 1;
  end
  axiif vif();
   initial begin
  uvm_config_db#(virtual axiif)::set(null,"*","vif",vif);
  end
  axi_slave DUT(
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
endmodule

