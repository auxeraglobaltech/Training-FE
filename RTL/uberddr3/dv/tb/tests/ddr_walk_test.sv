// ============================================================================
//  ddr_walk_test.sv  —  bank / row / column address walk
// ============================================================================
class ddr_walk_test extends ddr_base_test;
  `uvm_component_utils(ddr_walk_test)
  function new(string name, uvm_component parent); super.new(name,parent); endfunction
  task run_phase(uvm_phase phase);
    ddr_walk_seq seq;
    phase.raise_objection(this);
    wait_calib();
    seq = ddr_walk_seq::type_id::create("seq");
    seq.start(env.agent.seqr);
    #500ns;
    phase.drop_objection(this);
  endtask
endclass : ddr_walk_test
