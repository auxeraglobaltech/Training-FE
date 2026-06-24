// ============================================================================
//  noc_random_test.sv  —  random mixed traffic from one master
// ============================================================================
class noc_random_test extends noc_base_test;
  `uvm_component_utils(noc_random_test)
  function new(string name, uvm_component parent); super.new(name,parent); endfunction
  task run_phase(uvm_phase phase);
    rand_traffic_seq seq;
    phase.raise_objection(this);
    pre_body_delay();
    seq = rand_traffic_seq::type_id::create("seq");
    if (!seq.randomize() with { num == 60; }) `uvm_error("TEST","rand failed")
    seq.start(env.m0_agent.seqr);
    #500ns;
    phase.drop_objection(this);
  endtask
endclass : noc_random_test
