//Hi
class ibex_base_test extends uvm_test;
  `uvm_component_utils(ibex_base_test)

  ibex_env       env;
  virtual ibex_if vif;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual ibex_if)::get(this, "", "vif", vif))
      `uvm_fatal("TEST", "No virtual interface found in config_db")
    env = ibex_env::type_id::create("env", this);
  endfunction

  task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    #1ms;
    phase.drop_objection(this);
  endtask

endclass
