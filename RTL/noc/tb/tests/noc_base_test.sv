// ============================================================================
//  noc_base_test.sv  —  base test: builds the environment
// ----------------------------------------------------------------------------
//  Derived tests start sequences in run_phase.  The base just builds noc_env
//  and reports the UVM error count so a clean run prints a clear PASS/FAIL.
// ============================================================================
class noc_base_test extends uvm_test;
  `uvm_component_utils(noc_base_test)

  noc_env env;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = noc_env::type_id::create("env", this);
  endfunction

  // give the design a few cycles to settle after reset
  task pre_body_delay();
    #200ns;
  endtask

  task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    pre_body_delay();
    `uvm_info("TEST","base test: no stimulus (override run_phase in derived test)", UVM_LOW)
    #200ns;
    phase.drop_objection(this);
  endtask

  function void report_phase(uvm_phase phase);
    uvm_report_server svr = uvm_report_server::get_server();
    if (svr.get_severity_count(UVM_ERROR)==0 && svr.get_severity_count(UVM_FATAL)==0)
      `uvm_info("RESULT","** TEST PASSED **", UVM_NONE)
    else
      `uvm_info("RESULT","** TEST FAILED **", UVM_NONE)
  endfunction

endclass : noc_base_test
