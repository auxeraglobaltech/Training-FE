class ibex_env extends uvm_env;
  `uvm_component_utils(ibex_env)

  ibex_agent      agent;
  ibex_scoreboard scoreboard;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    agent      = ibex_agent::type_id::create("agent", this);
    scoreboard = ibex_scoreboard::type_id::create("scoreboard", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    agent.mon.ap.connect(scoreboard.analysis_export);
  endfunction

endclass
