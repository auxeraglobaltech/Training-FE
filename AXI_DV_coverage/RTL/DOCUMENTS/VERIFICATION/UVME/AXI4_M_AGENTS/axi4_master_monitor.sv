/*************************************************
File name:axi4_master_monitor.sv
Description: This module contains monitor that samples the 
DUT signals through the virtual interface and converts the 
signal level activity to the transaction level.
**************************************************/

//axi4_master_monitor is derived from uvm_monitor base class
class axi4_master_monitor extends uvm_monitor;
  
  //factory registration
  `uvm_component_utils(axi4_master_monitor) 
 
  //virtual interface for sampling DUT data
  virtual axi4_master_intf interface_inst; 
  
  //seq_item handle to be used in scoreboard and coverage
  axi4_master_seq_item seq_item_con1; 
  
  // TLM analysis_port handle: port_con1
  uvm_analysis_port #(axi4_master_seq_item) port_con1; 

  //constructor
  function new (string name, uvm_component parent);
    super.new(name, parent);
  endfunction
 
  //build phase
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    port_con1 = new("port_con1", this); 

    // virtual Interface : to sample all the signal values of the DUT	
    if(!uvm_config_db#(virtual axi4_master_intf)::get(this,"","interface_inst",interface_inst))
    `uvm_fatal(get_name(),$sformatf("monitor: uvm_config_db get failed: interface_inst\n")) 
  endfunction
 
  //uvm run phase
  task run_phase(uvm_phase phase);
    begin
      forever
      begin
        seq_item_con1 = axi4_master_seq_item::type_id::create("seq_item_con1");
		
        // sampling of data should always be at posedge of clock
        @(posedge interface_inst.axi_aclk); 		
        seq_item_con1.master_wren   = interface_inst.master_wren;
        seq_item_con1.master_waddr  = interface_inst.master_waddr;  
        seq_item_con1.master_wid    = interface_inst.master_wid;
        seq_item_con1.master_wlen   = interface_inst.master_wlen;
        seq_item_con1.master_wburst = interface_inst.master_wburst;  
        seq_item_con1.master_wdata  = interface_inst.master_wdata;
        seq_item_con1.master_wstrb  = interface_inst.master_wstrb;

        seq_item_con1.master_rden   = interface_inst.master_rden;
        seq_item_con1.master_raddr  = interface_inst.master_raddr;
        seq_item_con1.master_rlen   = interface_inst.master_rlen;
        seq_item_con1.master_rburst = interface_inst.master_rburst;
        seq_item_con1.master_rid    = interface_inst.master_rid;

        seq_item_con1.axi_areset_n  = interface_inst.axi_areset_n;
        seq_item_con1.axi_awready   = interface_inst.axi_awready;
        seq_item_con1.axi_wready    = interface_inst.axi_wready;
        seq_item_con1.axi_bresp     = interface_inst.axi_bresp;
        seq_item_con1.axi_bvalid    = interface_inst.axi_bvalid;
        seq_item_con1.axi_bid       = interface_inst.axi_bid;

        seq_item_con1.axi_arready   = interface_inst.axi_arready;
        seq_item_con1.axi_rvalid    = interface_inst.axi_rvalid;
        seq_item_con1.axi_rid       = interface_inst.axi_rid;
        seq_item_con1.axi_rlast     = interface_inst.axi_rlast;
        seq_item_con1.axi_rresp     = interface_inst.axi_rresp;
        seq_item_con1.axi_rdata     = interface_inst.axi_rdata; 

        seq_item_con1.master_rdata  = interface_inst.master_rdata; 
        seq_item_con1.axi_awaddr    = interface_inst.axi_awaddr; 
        seq_item_con1.axi_awvalid   = interface_inst.axi_awvalid; 
        seq_item_con1.axi_awid      = interface_inst.axi_awid; 
        seq_item_con1.axi_awlen     = interface_inst.axi_awlen; 
        seq_item_con1.axi_awburst   = interface_inst.axi_awburst; 
        seq_item_con1.axi_wdata     = interface_inst.axi_wdata; 
        seq_item_con1.axi_wvalid    = interface_inst.axi_wvalid; 
        seq_item_con1.axi_wid       = interface_inst.axi_wid; 
        seq_item_con1.axi_wlast     = interface_inst.axi_wlast; 
        seq_item_con1.axi_wstrb     = interface_inst.axi_wstrb; 
        seq_item_con1.axi_bready    = interface_inst.axi_bready; 
        seq_item_con1.axi_araddr    = interface_inst.axi_araddr; 
        seq_item_con1.axi_arvalid   = interface_inst.axi_arvalid; 
        seq_item_con1.axi_arid      = interface_inst.axi_arid; 
        seq_item_con1.axi_arlen     = interface_inst.axi_arlen; 
        seq_item_con1.axi_arburst   = interface_inst.axi_arburst; 
        seq_item_con1.axi_rready    = interface_inst.axi_rready; 


        //seq_item_con1.print();
        port_con1.write(seq_item_con1); //analysis port write function, to be used in SB & covg
      end
    end
  endtask
 
endclass


