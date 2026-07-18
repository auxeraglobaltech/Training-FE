/*************************************************
File name:axi4_m_reset_test.sv
Description:

**************************************************/

class axi4_m_reset_test extends axi4_m_base_test;
 
  `uvm_component_utils(axi4_m_reset_test)
 
    
  //constructor
  function new(string name = "axi4_m_reset_test",uvm_component parent=null);
    super.new(name,parent);
  endfunction
 

  //uvm build phase
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
  endfunction

 
 // run phase starting
  task run_phase(uvm_phase phase);

    phase.raise_objection(this);
	
    `uvm_info(get_name(),$sformatf("step 1 : inside test"),UVM_MEDIUM)
   
  repeat(20)
    begin
/************************************************************************/
    //scenario 1 - reset is asserted and all other inputs are randomized
	seq_inst.scenario = 1;
    seq_inst.axi_areset_n_seq = 0;
    seq_inst.start(env_inst.agent_inst.sequencer_inst);
/************************************************************************/
/*    //scenario 2 - reset is de-asserted and all other inputs are zero    
	seq_inst.scenario = 2;
    seq_inst.axi_areset_n_seq  = 1;
    seq_inst.axi_awready_seq   = 0;
    seq_inst.axi_wready_seq    = 0;
    seq_inst.axi_bid_seq       = 0;
    seq_inst.axi_bresp_seq     = 0;
    seq_inst.axi_bvalid_seq    = 0;
    seq_inst.axi_arready_seq   = 0;
    seq_inst.axi_rid_seq       = 0;
    seq_inst.axi_rdata_seq     = 0;
    seq_inst.axi_rlast_seq     = 0;
    seq_inst.axi_rvalid_seq    = 0;
    seq_inst.axi_rresp_seq     = 0;
    seq_inst.master_wren_seq   = 0;
    seq_inst.master_waddr_seq  = 0;
    seq_inst.master_wid_seq    = 0;
    seq_inst.master_wlen_seq   = 0;
    seq_inst.master_wburst_seq = 0;
    seq_inst.master_wdata_seq  = 0;
    seq_inst.master_wstrb_seq  = 0;
    seq_inst.master_rden_seq   = 0;
    seq_inst.master_raddr_seq  = 0;
    seq_inst.master_rlen_seq   = 0;
    seq_inst.master_rburst_seq = 0;
    seq_inst.master_rid_seq    = 0;      
    seq_inst.start(env_inst.agent_inst.sequencer_inst);
/************************************************************************/
    end

	`uvm_info(get_name(),$sformatf("step 6 : inside test done "),UVM_MEDIUM)

    phase.drop_objection(this);

    uvm_test_done.set_drain_time(this,1000);
  
  endtask
 
endclass
