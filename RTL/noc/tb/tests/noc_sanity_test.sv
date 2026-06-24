// ============================================================================
//  noc_sanity_test.sv  —  one master, connectivity W+R to every target + DECERR
// ----------------------------------------------------------------------------
//  The UVM equivalent of the datapath smoke: proves the env (driver, monitors,
//  scoreboard, responders) works end-to-end and the DUT routes/converts/errors
//  correctly under a single, ordered stream.
// ============================================================================
class noc_sanity_test extends noc_base_test;
  `uvm_component_utils(noc_sanity_test)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    connectivity_seq seq;
    phase.raise_objection(this);
    pre_body_delay();
    seq = connectivity_seq::type_id::create("seq");
    seq.start(env.m0_agent.seqr);
    #500ns;
    phase.drop_objection(this);
  endtask

endclass : noc_sanity_test
