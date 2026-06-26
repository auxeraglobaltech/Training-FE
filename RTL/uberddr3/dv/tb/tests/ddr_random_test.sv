// ============================================================================
//  ddr_random_test.sv  —  randomised mixed read/write traffic
// ============================================================================
class ddr_random_test extends ddr_base_test;
  `uvm_component_utils(ddr_random_test)
  function new(string name, uvm_component parent); super.new(name,parent); endfunction
  task run_phase(uvm_phase phase);
    ddr_random_seq seq;
    phase.raise_objection(this);
    wait_calib();
    seq = ddr_random_seq::type_id::create("seq");
    if (!seq.randomize() with { num == 80; }) `uvm_error("TEST","rand failed")
    seq.start(env.agent.seqr);
    #1000ns;
    phase.drop_objection(this);
  endtask
endclass : ddr_random_test
