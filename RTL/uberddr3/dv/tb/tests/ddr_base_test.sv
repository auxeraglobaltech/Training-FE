// ============================================================================
//  ddr_base_test.sv  —  base test: builds the env, waits for calibration
// ============================================================================
class ddr_base_test extends uvm_test;
  `uvm_component_utils(ddr_base_test)

  ddr_env       env;
  virtual wb_if vif;

  function new(string name, uvm_component parent); super.new(name,parent); endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = ddr_env::type_id::create("env", this);
    if (!uvm_config_db#(virtual wb_if)::get(this,"","vif",vif))
      `uvm_fatal("TEST","no wb vif")
  endfunction

  // wait for calibration before any derived stimulus
  task wait_calib();
    `uvm_info("TEST","waiting for calibration...", UVM_LOW)
    wait (vif.calib_complete === 1'b1);
    `uvm_info("TEST", $sformatf("calibration complete @ %0t", $time), UVM_LOW)
  endtask

  task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    wait_calib();
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

endclass : ddr_base_test
