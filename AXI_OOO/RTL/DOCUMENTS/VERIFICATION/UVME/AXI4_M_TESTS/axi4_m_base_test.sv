/*************************************************
File name:axi4_m_base_test.sv
Description:

**************************************************/

class axi4_m_base_test extends uvm_test;
 
  `uvm_component_utils(axi4_m_base_test)
 
  axi4_master_env env_inst;  // uvm environment handle
  axi4_master_seq seq_inst;  // uvm sequence handle
  
  //constructor
  function new(string name = "axi4_master_base_test",uvm_component parent=null);
    super.new(name,parent);
  endfunction
 

 //uvm build phase
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    //creating objects for handles
    env_inst = axi4_master_env::type_id::create("env_inst", this);
    seq_inst = axi4_master_seq::type_id::create("seq_inst",this);
  endfunction

 
 // run phase starting
 //
  task run_phase(uvm_phase phase);

    phase.raise_objection(this);
	
    `uvm_info(get_name(),$sformatf("step 1 : inside test"),UVM_MEDIUM)
   
//  repeat(20)
//   begin
/************************************************************************/
    //scenario 1 - reset is asserted and all other inputs are randomized
//
//end
//
	`uvm_info(get_name(),$sformatf("step 6 : inside test done "),UVM_MEDIUM)

    phase.drop_objection(this);

    //uvm_test_done.set_drain_time(this,1000);
  
  endtask
  //
 
endclass


