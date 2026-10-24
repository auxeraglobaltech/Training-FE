class ibex_env extends uvm_env;
  `uvm_component_utils(ibex_env)

  ibex_agent      agent;
  ibex_scoreboard scoreboard;
  ibex_console    console;
  ibex_c2sv_mbox  c2sv;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    agent      = ibex_agent::type_id::create("agent", this);
    scoreboard = ibex_scoreboard::type_id::create("scoreboard", this);
    console    = ibex_console::type_id::create("console", this);
    c2sv       = ibex_c2sv_mbox::type_id::create("c2sv", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    agent.mon.ap.connect(scoreboard.analysis_export);
  endfunction

endclass
