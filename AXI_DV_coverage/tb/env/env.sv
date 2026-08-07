class env extends uvm_env;
  `uvm_component_utils(env)
  agent agt;
  scoreboard scb;
 axi_coverage cov;
 axi_slave_mem_model mem_model;  
  function new(string name="env",uvm_component parent);
    super.new(name,parent);
  endfunction
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    scb=scoreboard::type_id::create("scb",this);
    agt=agent::type_id::create("agt",this);
    cov=axi_coverage::type_id::create("cov",this);
    mem_model =axi_slave_mem_model::type_id::create("mem_model", this);
  endfunction
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    agt.mon.ap.connect(scb.imp);
    agt.mon.ap.connect(cov.analysis_export);
  endfunction
endclass

