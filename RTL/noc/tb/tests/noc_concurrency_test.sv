// ============================================================================
//  noc_concurrency_test.sv  —  both masters, independent mixed traffic
// ----------------------------------------------------------------------------
//  Exercises routing + arbitration + bridge concurrently across the fabric.
//  The scoreboard accepts any legal arbitration interleaving.
// ============================================================================
class noc_concurrency_test extends noc_base_test;
  `uvm_component_utils(noc_concurrency_test)
  function new(string name, uvm_component parent); super.new(name,parent); endfunction
  task run_phase(uvm_phase phase);
    concurrent_mixed_vseq vseq;
    phase.raise_objection(this);
    pre_body_delay();
    vseq = concurrent_mixed_vseq::type_id::create("vseq");
    vseq.start(env.vseqr);
    #1000ns;
    phase.drop_objection(this);
  endtask
endclass : noc_concurrency_test
