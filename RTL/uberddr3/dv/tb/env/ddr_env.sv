// ============================================================================
//  ddr_env.sv  —  UberDDR3 (Wishbone) UVM environment
// ----------------------------------------------------------------------------
//  One active WB master agent driving the controller's native interface, a
//  golden-memory scoreboard, and functional coverage. The vif is published by
//  the UVM top and fetched here.
// ============================================================================
class ddr_env extends uvm_env;
  `uvm_component_utils(ddr_env)

  wb_master_agent agent;
  ddr_scoreboard  sb;
  ddr_coverage    cov;

  function new(string name, uvm_component parent); super.new(name,parent); endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    agent = wb_master_agent::type_id::create("agent", this);
    sb    = ddr_scoreboard ::type_id::create("sb", this);
    cov   = ddr_coverage   ::type_id::create("cov", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    agent.mon.ap.connect(sb.ap_imp);
    agent.mon.ap.connect(cov.analysis_export);
  endfunction

endclass : ddr_env
