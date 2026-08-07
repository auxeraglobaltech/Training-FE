interface axiif;
    parameter DATA_WIDTH    = 32;
    parameter ADDRESS_WIDTH = 32;

   //INPUTS-------------------------
    logic                         axi_aclk;
	logic 			              axi_areset_n ;

	logic 	[31:0]				  slave_rdata;

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
    
     //OUTPUTS------------------------------------
    logic                       slave_wren  ;
	logic   [31:0]              slave_waddr ;
	logic	[31:0]	            slave_wdata   ;
	logic		                slave_rden  ;
	logic	[31:0]	            slave_raddr;


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


endinterface

