// ============================================================================
//  noc_priority_test.sv  —  both masters storm S0 with M1 higher priority
// ----------------------------------------------------------------------------
//  M1 QoS high, M0 QoS low.  Strict priority means M1 wins under contention
//  (priority-honoured SVA), and a low-priority M0 may starve (by design) —
//  the bounded-wait SVA is the catch for that, demonstrated separately.
// ============================================================================
class noc_priority_test extends noc_base_test;
  `uvm_component_utils(noc_priority_test)
  function new(string name, uvm_component parent); super.new(name,parent); endfunction
  task run_phase(uvm_phase phase);
    both_storm_vseq vseq;
    phase.raise_objection(this);
    pre_body_delay();
    vseq = both_storm_vseq::type_id::create("vseq");
    vseq.base = noc_pkg::S0_BASE; vseq.qos0 = 4'd2; vseq.qos1 = 4'd12; // M1 higher
    vseq.start(env.vseqr);
    #1000ns;
    // Priority is verified cycle-accurately by arb_sva (ap_prio_m1: whenever
    // both request and M1 has strictly higher QoS, M1 must be granted).  If that
    // assertion does not fire and the scoreboard is clean, priority is honoured.
    begin
      real s = env.sb.share_m0(noc_pkg::TGT_S0);
      `uvm_info("PRIO", $sformatf("S0 completion share: M0(lo)=%.2f M1(hi)=%.2f (priority checked by SVA)",
                s, 1.0-s), UVM_LOW)
    end
    phase.drop_objection(this);
  endtask
endclass : noc_priority_test
