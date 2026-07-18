/*************************************************
File name:axi4_master_seq_item.sv
Description: This module contains Inputs to be randomized 
and constraints if any.
**************************************************/

//axi4_master_seq_item is derived from uvm_sequence_item base class
class axi4_master_seq_item extends uvm_sequence_item;
  parameter DATA_WIDTH    = 32;
  parameter ADDRESS_WIDTH = 32;
   //INPUTS----------------------------------------
  rand  logic                       master_wren  ;
  rand  logic   [31:0]              master_waddr ;
  rand	logic	[3:0]	            master_wid   ;
  rand	logic	[7:0]	            master_wlen  ;
  rand	logic	[1:0]	            master_wburst;
  rand	logic 	[31:0]	            master_wdata ;
  rand	logic	[3:0]	            master_wstrb ;

  rand	logic 			            master_rden  ;
  rand	logic 	[31:0]              master_raddr ;
  rand	logic 	[7:0]	            master_rlen  ;
  rand	logic 	[1:0]	            master_rburst;
  rand	logic 	[3:0]	            master_rid   ;

  rand	logic 			            axi_areset_n ;
  rand	logic 			            axi_awready  ;
  rand	logic 			            axi_wready   ;
  rand	logic 	[1:0] 	            axi_bresp    ;
  rand	logic 			            axi_bvalid   ;
  rand	logic 	[3:0] 	            axi_bid      ;

  rand	logic 	    	            axi_arready  ;
  rand	logic 			            axi_rvalid   ;
  rand	logic 	[3:0] 	            axi_rid      ; 	
  rand	logic 			            axi_rlast    ;
  rand	logic 	[1:0] 	            axi_rresp    ;
  rand	logic 	[DATA_WIDTH-1:0]    axi_rdata    ;

  //OUTPUTS----------------------------------------
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

  //factory registration
  `uvm_object_utils_begin(axi4_master_seq_item)
    `uvm_field_int(master_wren ,UVM_ALL_ON)
    `uvm_field_int(master_waddr ,UVM_ALL_ON)
    `uvm_field_int(master_wid ,UVM_ALL_ON)
    `uvm_field_int(master_wlen ,UVM_ALL_ON)
    `uvm_field_int(master_wburst ,UVM_ALL_ON)
    `uvm_field_int(master_wstrb ,UVM_ALL_ON)

    `uvm_field_int(master_rden ,UVM_ALL_ON)
    `uvm_field_int(master_raddr ,UVM_ALL_ON)
    `uvm_field_int(master_rlen ,UVM_ALL_ON)
    `uvm_field_int(master_rburst ,UVM_ALL_ON)
    `uvm_field_int(master_rid ,UVM_ALL_ON)

    `uvm_field_int(axi_areset_n ,UVM_ALL_ON)
    `uvm_field_int(axi_awready ,UVM_ALL_ON)
    `uvm_field_int(axi_wready ,UVM_ALL_ON)
    `uvm_field_int(axi_bresp ,UVM_ALL_ON)
    `uvm_field_int(axi_bvalid ,UVM_ALL_ON)
    `uvm_field_int(axi_bid ,UVM_ALL_ON)

    `uvm_field_int(axi_arready ,UVM_ALL_ON)
    `uvm_field_int(axi_rvalid ,UVM_ALL_ON)
    `uvm_field_int(axi_rid ,UVM_ALL_ON)
    `uvm_field_int(axi_rlast ,UVM_ALL_ON)
    `uvm_field_int(axi_rresp ,UVM_ALL_ON)
    `uvm_field_int(axi_rdata ,UVM_ALL_ON)

    `uvm_field_int(master_rdata ,UVM_ALL_ON)

    `uvm_field_int(axi_awaddr ,UVM_ALL_ON)
    `uvm_field_int(axi_awvalid ,UVM_ALL_ON)
    `uvm_field_int(axi_awid ,UVM_ALL_ON)
    `uvm_field_int(axi_awlen ,UVM_ALL_ON)
    `uvm_field_int(axi_awburst ,UVM_ALL_ON)

    `uvm_field_int(axi_wdata ,UVM_ALL_ON)
    `uvm_field_int(axi_wvalid ,UVM_ALL_ON)
    `uvm_field_int(axi_wid ,UVM_ALL_ON)
    `uvm_field_int(axi_wlast ,UVM_ALL_ON)
    `uvm_field_int(axi_wstrb ,UVM_ALL_ON)

    `uvm_field_int(axi_bready ,UVM_ALL_ON)

    `uvm_field_int(axi_araddr ,UVM_ALL_ON)
    `uvm_field_int(axi_arvalid ,UVM_ALL_ON)
    `uvm_field_int(axi_arid ,UVM_ALL_ON)
    `uvm_field_int(axi_arlen ,UVM_ALL_ON)
    `uvm_field_int(axi_arburst ,UVM_ALL_ON)

    `uvm_field_int(axi_rready ,UVM_ALL_ON)    
  `uvm_object_utils_end

  constraint const_master_wburst {master_wburst < 3;} 
 // master_wburst type : 00=> fixed, 01=> increment, 10=> wrap, 11 => reserved

  constraint const_master_rburst {master_rburst < 3;} 
 // master_rburst type : 00=> fixed, 01=> increment, 10=> wrap, 11 => reserved


  //constructor
  function new(string name="axi4_master_seq_item");
    super.new(name);
  endfunction

endclass

