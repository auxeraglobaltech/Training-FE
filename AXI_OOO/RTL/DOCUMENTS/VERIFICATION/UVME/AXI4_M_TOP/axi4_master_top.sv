/********************************************************************************
File name:axi4_master_top.sv
Description: This is the top most module in the tetbench
This module has: RTL instance, Interface instance, UVM - run_test, wave dump etc;
********************************************************************************/
module top;

  // UVM package
  import uvm_pkg::*;
  `include "uvm_macros.svh"
        
  // TB package
  import pkg::*;

  // random clock generation
  logic axi_aclk;                               // clock declaration
  int timeperiod = $urandom_range(10,50);       //random timeperiod calculation
  int dutycycle  = $urandom_range (40,60);      //random dutycycle calculation
  int on_time    = (timeperiod*dutycycle)/100;  //ton calculation
  int off_time   = timeperiod - on_time;        //toff calculation

  initial
    begin
      axi_aclk = 0;
      forever
        begin
          #off_time axi_aclk = 1;  
          #on_time  axi_aclk = 0;
        end
    end
  
   
  // creatinng instance of interface, inorder to connect DUT and testcase
  axi4_master_intf interface_inst(axi_aclk);
      
  //  RTL instance, interface signals are connected to the DUT ports --------------------------------
  axi_master DUT(// inputs
                 .axi_aclk	    (interface_inst.axi_aclk),
                 .master_wren   (interface_inst.master_wren),
	             .master_waddr  (interface_inst.master_waddr),
		         .master_wid    (interface_inst.master_wid),
		         .master_wlen   (interface_inst.master_wlen),
		         .master_wburst (interface_inst.master_wburst),
		         .master_wdata  (interface_inst.master_wdata),
	             .master_wstrb  (interface_inst.master_wstrb),
	             .master_rden   (interface_inst.master_rden),
	             .master_raddr  (interface_inst.master_raddr),
		         .master_rlen   (interface_inst.master_rlen),
		         .master_rburst (interface_inst.master_rburst),
		         .master_rid    (interface_inst.master_rid),
	             .axi_areset_n  (interface_inst.axi_areset_n),
	             .axi_awready   (interface_inst.axi_awready),
	             .axi_wready    (interface_inst.axi_wready),
	             .axi_bresp     (interface_inst.axi_bresp),
	             .axi_bvalid    (interface_inst.axi_bvalid),
	 	         .axi_bid       (interface_inst.axi_bid),
	             .axi_arready   (interface_inst.axi_arready),
	             .axi_rvalid    (interface_inst.axi_rvalid),
 	             .axi_rid       (interface_inst.axi_rid),
	             .axi_rlast     (interface_inst.axi_rlast),
	 	         .axi_rresp     (interface_inst.axi_rresp),
	             .axi_rdata     (interface_inst.axi_rdata),
				 // outputs   
				 .master_rdata	(interface_inst.master_rdata),
                 .axi_awaddr    (interface_inst.axi_awaddr),
				 .axi_awvalid   (interface_inst.axi_awvalid),
	 			 .axi_awid      (interface_inst.axi_awid),
	 			 .axi_awlen     (interface_inst.axi_awlen),
	 			 .axi_awburst 	(interface_inst.axi_awburst),
	 	         .axi_wdata     (interface_inst.axi_wdata),
				 .axi_wvalid    (interface_inst.axi_wvalid),
	 		     .axi_wid       (interface_inst.axi_wid),
				 .axi_wlast     (interface_inst.axi_wlast),
	             .axi_wstrb     (interface_inst.axi_wstrb),
				 .axi_bready    (interface_inst.axi_bready),
	             .axi_araddr    (interface_inst.axi_araddr),
				 .axi_arvalid   (interface_inst.axi_arvalid),
	 			 .axi_arid      (interface_inst.axi_arid),
	 			 .axi_arlen     (interface_inst.axi_arlen),
	 		     .axi_arburst   (interface_inst.axi_arburst),
				 .axi_rready    (interface_inst.axi_rready)                 
                );

  // UVM_test, set interface in config_db--------------------------------------------------------------
  initial begin
    uvm_config_db#(virtual axi4_master_intf)::set(uvm_root::get(),"*","interface_inst",interface_inst);
    // start point - UVM   this is a task, coded inside UVM library
    run_test("axi4_m_base_test");
  end

  // wave_dump ----------------------------------------------------------------------------------------
  initial begin
    $shm_open("wave.shm");
    $shm_probe("ACTMF");
  end   
         
endmodule
