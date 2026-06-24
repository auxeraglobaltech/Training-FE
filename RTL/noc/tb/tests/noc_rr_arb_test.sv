// ============================================================================
//  noc_rr_arb_test.sv  —  both masters storm S0 at EQUAL priority
// ----------------------------------------------------------------------------
//  Forces sustained contention so the round-robin tie-break is exercised.
//  Data/routing are checked by the scoreboard; fairness is checked by the
//  arb SVA (Phase-5 assertions).  Run with BUG=RR_FREEZE to demonstrate the
//  round-robin pointer-update defect.
// ============================================================================
class noc_rr_arb_test extends noc_base_test;
  `uvm_component_utils(noc_rr_arb_test)
  function new(string name, uvm_component parent); super.new(name,parent); endfunction
  task run_phase(uvm_phase phase);
    both_storm_vseq vseq;
    phase.raise_objection(this);
    pre_body_delay();
    vseq = both_storm_vseq::type_id::create("vseq");
    vseq.base = noc_pkg::S0_BASE; vseq.qos0 = 4'd0; vseq.qos1 = 4'd0;  // equal priority
    vseq.start(env.vseqr);
    #1000ns;
    // Completion share (info only — both fixed-count sequences finish, so this
    // is ~0.5 by construction).  Round-robin correctness is checked cycle-
    // accurately by the arb_sva assertions (mutex + no illegal grant); data and
    // routing under contention are checked by the scoreboard.
    begin
      real s = env.sb.share_m0(noc_pkg::TGT_S0);
      `uvm_info("RR", $sformatf("S0 completion share: M0=%.2f M1=%.2f (arbitration checked by SVA)",
                s, 1.0-s), UVM_LOW)
    end
    phase.drop_objection(this);
  endtask
endclass : noc_rr_arb_test
