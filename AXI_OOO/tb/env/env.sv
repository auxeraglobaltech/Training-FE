class env extends uvm_env;
  `uvm_component_utils(env)
  agent agt;
  scoreboard scb;
 axi_slave_mem_model   mem_model;  
  function new(string name="env",uvm_component parent);
    super.new(name,parent);
  endfunction
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    scb=scoreboard::type_id::create("scb",this);
    agt=agent::type_id::create("agt",this);
    mem_model =axi_slave_mem_model::type_id::create("mem_model", this);
  endfunction
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    agt.mon.aw_ap.connect(scb.aw_imp);
    agt.mon.w_ap.connect(scb.w_imp);
    agt.mon.b_ap.connect(scb.b_imp);
    agt.mon.ar_ap.connect(scb.ar_imp);
    agt.mon.r_ap.connect(scb.r_imp);

  endfunction
endclass

