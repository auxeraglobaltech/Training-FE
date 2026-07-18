/*************************************************
File name:axi4_master_driver.sv
Description: This module receives the stimulus from 
seq_item -> sequence -> sequencer and drives on interface signals to DUT
**************************************************/

//axi4_master_driver is derived from uvm_driver base class
class axi4_master_driver extends uvm_driver #(axi4_master_seq_item);
  
  //factory registration
  `uvm_component_utils(axi4_master_driver)  

  virtual axi4_master_intf interface_inst;  //virtual interface handle
  axi4_master_seq_item seq_item_inst;       //seq item handle

  //constructor
  function new (string name = "axi4_master_driver", uvm_component parent);
    super.new(name, parent);
  endfunction

  //build phase
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
	
    //connecting to virtual interface using uvm_congifg_db get() method 
    if(!uvm_config_db#(virtual axi4_master_intf)::get(this, "", "interface_inst", interface_inst))
        `uvm_fatal("NO_VIF",{"virtual interface must be set for: ",get_full_name(),".interface_inst"})   
  endfunction

  //run phase
  virtual task run_phase(uvm_phase phase);
    super.run_phase(phase);
//
      interface_inst.axi_areset_n  = 0;      // during reset (active low)

      interface_inst.axi_awready   = 0;
      interface_inst.axi_wready    = 0;
      interface_inst.axi_bid       = 0;
      interface_inst.axi_bresp     = 0;
      interface_inst.axi_bvalid    = 0;
      interface_inst.axi_arready   = 0;
      interface_inst.axi_rid       = 0;
      interface_inst.axi_rdata     = 0;
      interface_inst.axi_rlast     = 0;
      interface_inst.axi_rvalid    = 0;
      interface_inst.axi_rresp     = 0;
      interface_inst.master_wren   = 0;
      interface_inst.master_waddr  = 0;
      interface_inst.master_wid    = 0;
      interface_inst.master_wlen   = 0;
      interface_inst.master_wburst = 0;
      interface_inst.master_wdata  = 0;
      interface_inst.master_wstrb  = 0;
      interface_inst.master_rden   = 0;
      interface_inst.master_raddr  = 0;
      interface_inst.master_rlen   = 0;
      interface_inst.master_rburst = 0;
      interface_inst.master_rid    = 0;     
    
    repeat(2) 
      begin
        @(negedge interface_inst.axi_aclk);
          interface_inst.axi_areset_n = ~interface_inst.axi_areset_n; // toggle reset
      end
/*
    @(negedge interface_inst.axi_aclk);
    interface_inst.axi_areset_n = 0; // reset

    @(negedge interface_inst.axi_aclk);
    interface_inst.axi_areset_n = 1; // out of reset
*/
//
    //taking seq_item from sequence and driving on interface -----------------
    forever
      begin
	    @(negedge interface_inst.axi_aclk);      
        seq_item_port.get_next_item(seq_item_inst);	  
	    `uvm_info(get_name(),$sformatf("step 3 : inside driver - run phase "),UVM_MEDIUM)
/*      
        if(seq_item_inst.axi_areset_n == 0)
          begin
            interface_inst.axi_awready   = 0;
            interface_inst.axi_wready    = 0;
            interface_inst.axi_bid       = 0;
            interface_inst.axi_bresp     = 0;
            interface_inst.axi_bvalid    = 0;
            interface_inst.axi_arready   = 0;
            interface_inst.axi_rid       = 0; 
            interface_inst.axi_rdata     = 0;
            interface_inst.axi_rlast     = 0;
            interface_inst.axi_rvalid    = 0;
            interface_inst.axi_rresp     = 0;
            interface_inst.master_wren   = 0;
            interface_inst.master_waddr  = 0;
            interface_inst.master_wid    = 0;
            interface_inst.master_wlen   = 0;
            interface_inst.master_wburst = 0;
            interface_inst.master_wdata  = 0;
            interface_inst.master_wstrb  = 0;
            interface_inst.master_rden   = 0;
            interface_inst.master_raddr  = 0;
            interface_inst.master_rlen   = 0;
            interface_inst.master_rburst = 0;
            interface_inst.master_rid    = 0;
            interface_inst.axi_areset_n  = 0;            
          end
//
        else if(seq_item_inst.axi_areset_n == 1)
          begin
        //seq_item_inst.print();
*/            
        // sequence item to interface -> this will reach RTL
            interface_inst.master_wren   = seq_item_inst.master_wren;
            interface_inst.master_waddr  = seq_item_inst.master_waddr;  
            interface_inst.master_wid    = seq_item_inst.master_wid;
            interface_inst.master_wlen   = seq_item_inst.master_wlen;
            interface_inst.master_wburst = seq_item_inst.master_wburst;  
            interface_inst.master_wdata  = seq_item_inst.master_wdata;
            interface_inst.master_wstrb  = seq_item_inst.master_wstrb;

            interface_inst.master_rden   = seq_item_inst.master_rden;
            interface_inst.master_raddr  = seq_item_inst.master_raddr;
            interface_inst.master_rlen   = seq_item_inst.master_rlen;
            interface_inst.master_rburst = seq_item_inst.master_rburst;
            interface_inst.master_rid    = seq_item_inst.master_rid;

            interface_inst.axi_areset_n  = seq_item_inst.axi_areset_n;
            interface_inst.axi_awready   = seq_item_inst.axi_awready;
            interface_inst.axi_wready    = seq_item_inst.axi_wready;
            interface_inst.axi_bresp     = seq_item_inst.axi_bresp;
            interface_inst.axi_bvalid    = seq_item_inst.axi_bvalid;
            interface_inst.axi_bid       = seq_item_inst.axi_bid;

            interface_inst.axi_arready   = seq_item_inst.axi_arready;
            interface_inst.axi_rvalid    = seq_item_inst.axi_rvalid;
            interface_inst.axi_rid       = seq_item_inst.axi_rid;
            interface_inst.axi_rlast     = seq_item_inst.axi_rlast;
            interface_inst.axi_rresp     = seq_item_inst.axi_rresp;
            interface_inst.axi_rdata     = seq_item_inst.axi_rdata;    
         // end
        `uvm_info(get_name(),$sformatf("step 4 : inside driver - run phase - done"),UVM_MEDIUM)      
        seq_item_port.item_done();
      end	
  endtask
endclass
