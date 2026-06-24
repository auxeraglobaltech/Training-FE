// ============================================================================
//  noc_bridge_test.sv  —  AXI->APB bridge with PSLVERR injection on P0
// ----------------------------------------------------------------------------
//  Enables PSLVERR on the P0 responder and tells the scoreboard to expect
//  SLVERR for P0.  Verifies the bridge maps PSLVERR -> SLVERR (one B per write
//  burst).  Run with BUG=PSLVERR_SWALLOW to see the mapping break.
// ============================================================================
class noc_bridge_test extends noc_base_test;
  `uvm_component_utils(noc_bridge_test)
  function new(string name, uvm_component parent); super.new(name,parent); endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    // P0 responder asserts PSLVERR on every transfer
    uvm_config_db#(bit)::set(this, "env.p0_resp", "err_en", 1'b1);
  endfunction

  task run_phase(uvm_phase phase);
    storm_seq seq;
    phase.raise_objection(this);
    pre_body_delay();
    env.sb.expect_err[noc_pkg::TGT_P0] = 1'b1;   // scoreboard expects SLVERR for P0
    seq = storm_seq::type_id::create("seq");
    seq.base = noc_pkg::P0_BASE; seq.num = 20; seq.qos = 0;
    seq.start(env.m0_agent.seqr);
    #500ns;
    phase.drop_objection(this);
  endtask
endclass : noc_bridge_test
