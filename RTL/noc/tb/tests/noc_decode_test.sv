// ============================================================================
//  noc_decode_test.sv  —  range-edge routing + unmapped DECERR
// ============================================================================
class noc_decode_test extends noc_base_test;
  `uvm_component_utils(noc_decode_test)
  function new(string name, uvm_component parent); super.new(name,parent); endfunction
  task run_phase(uvm_phase phase);
    decode_boundary_seq seq;
    phase.raise_objection(this);
    pre_body_delay();
    seq = decode_boundary_seq::type_id::create("seq");
    seq.start(env.m0_agent.seqr);
    #500ns;
    phase.drop_objection(this);
  endtask
endclass : noc_decode_test
