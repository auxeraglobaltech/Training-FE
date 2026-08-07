/*************************************************
File name:axi4_m_readop_deviceidfailure_test.sv
Description:

**************************************************/
class axi4_m_readop_deviceidfailure_test extends axi4_m_base_test;
 
  `uvm_component_utils(axi4_m_readop_deviceidfailure_test)
 
  //constructor
  function new(string name = "axi4_m_readop_deviceidfailure_test",uvm_component parent=null);
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
    //scenario 9 - reset = de-asserted, master_wren = 0, master_rden = 1, master_rid != 3 & axi_rid != 3 
	seq_inst.scenario = 9;  
    seq_inst.start(env_inst.agent_inst.sequencer_inst);
/************************************************************************/    
    end

	`uvm_info(get_name(),$sformatf("step 6 : inside test done "),UVM_MEDIUM)

    phase.drop_objection(this);

//    uvm_test_done.set_drain_time(this,1000);
  
  endtask
 
endclass
