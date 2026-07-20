/*************************************************
File name:axi4_master_env.sv
Description: This module contains handles of agent, SB & covg
And conncects agent -> monitor to SB & covg

**************************************************/
//axi4_master_env is derived from uvm_env base class
class axi4_master_env extends uvm_env;
  
  //factory registration
  `uvm_component_utils(axi4_master_env) 

  axi4_master_agent agent_inst;            // agent handle
  axi4_master_scoreboard sb_inst;          // scorboard handle
  axi4_master_coverage coverage_func_inst; // coverage handle

  //constructor
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction
  
  //build phase
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    agent_inst 			= axi4_master_agent::type_id::create("agent_inst", this);
    sb_inst 			= axi4_master_scoreboard::type_id::create("sb_inst", this);
    coverage_func_inst 	= axi4_master_coverage::type_id::create("coverage_func_inst", this);
  endfunction : build_phase
  
  //connect phase 
  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    // monitor to scoreboard
    //connect agent, monitor and scoreboard using TLM interface
    agent_inst.monitor_inst.port_con1.connect(sb_inst.sb_port_con1);    
	
    // monitor to coverage
    agent_inst.monitor_inst.port_con1.connect(coverage_func_inst.analysis_export); 
 
  endfunction

endclass
