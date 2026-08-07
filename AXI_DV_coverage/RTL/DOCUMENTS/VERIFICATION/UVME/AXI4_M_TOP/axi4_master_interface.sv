/*************************************************
File name:axi4_master_interface.sv
Description: This module contains the interface construct 
is used to connect the design and testbench.
**************************************************/
interface axi4_master_intf(input logic axi_aclk);

    parameter DATA_WIDTH    = 32;
    parameter ADDRESS_WIDTH = 32;

  //INPUTS------------------------------------
    logic                       master_wren  ;
	logic   [31:0]              master_waddr ;
	logic	[3:0]	            master_wid   ;
	logic	[7:0]	            master_wlen  ;
	logic	[1:0]	            master_wburst;
	logic 	[31:0]	            master_wdata ;
	logic	[3:0]	            master_wstrb ;

	logic 			            master_rden  ;
	logic 	[31:0]              master_raddr ;
	logic 	[7:0]	            master_rlen  ;
	logic 	[1:0]	            master_rburst;
	logic 	[3:0]	            master_rid   ;

	logic 			            axi_areset_n ;
	logic 			            axi_awready  ;
	logic 			            axi_wready   ;
	logic 	[1:0] 	            axi_bresp    ;
	logic 			            axi_bvalid   ;
	logic 	[3:0] 	            axi_bid      ;

	logic 	    	            axi_arready  ;
	logic 			            axi_rvalid   ;
	logic 	[3:0] 	            axi_rid      ; 	
	logic 			            axi_rlast    ;
	logic 	[1:0] 	            axi_rresp    ;
	logic 	[DATA_WIDTH-1:0]    axi_rdata    ;

  //OUTPUTS-------------------------
	logic 	[31:0]				  master_rdata;

	logic 	[ADDRESS_WIDTH-1:0]   axi_awaddr  ;
	logic 						  axi_awvalid ;
	logic 	[3:0] 				  axi_awid    ;
	logic 	[7:0] 				  axi_awlen   ;
	logic 	[1:0] 				  axi_awburst ;	

	logic 	[DATA_WIDTH-1:0] 	  axi_wdata   ;
	logic 						  axi_wvalid  ;
	logic 	[3:0] 				  axi_wid     ;
	logic 						  axi_wlast   ;
	logic 	[(DATA_WIDTH>>3)-1:0] axi_wstrb   ;

	logic 						  axi_bready  ;

	logic 	[ADDRESS_WIDTH-1:0]	  axi_araddr  ;
	logic 	  					  axi_arvalid ;
	logic 	[3:0] 				  axi_arid    ;
	logic 	[7:0] 				  axi_arlen   ;
	logic 	[1:0] 				  axi_arburst ;
    
	logic 	    			      axi_rready  ;

endinterface

