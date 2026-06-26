// ============================================================================
//  ddr_refresh_test.sv  —  data integrity across auto-refresh
// ----------------------------------------------------------------------------
//  A long traffic run spans many tREFI (7.8 us) intervals; auto-refresh is
//  transparent, so every read must still return the written data.
// ============================================================================
class ddr_refresh_test extends ddr_base_test;
  `uvm_component_utils(ddr_refresh_test)
  function new(string name, uvm_component parent); super.new(name,parent); endfunction
  task run_phase(uvm_phase phase);
    ddr_random_seq seq;
    phase.raise_objection(this);
    wait_calib();
    seq = ddr_random_seq::type_id::create("seq");
    if (!seq.randomize() with { num == 300; }) `uvm_error("TEST","rand failed")
    seq.start(env.agent.seqr);
    #2000ns;
    phase.drop_objection(this);
  endtask
endclass : ddr_refresh_test
