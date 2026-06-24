// ============================================================================
//  arb_sva.sv  —  arbitration checker (bound to every noc_arbiter)
// ----------------------------------------------------------------------------
//  priority-honoured (always on) + mutual exclusion + grant-validity.
//  A bounded-wait (no-starvation) property is included but compiled OFF by
//  default (`ARB_CHECK_LIVENESS`) because strict priority is allowed to starve
//  a low-priority master by design; enable it only for the starvation demo.
// ============================================================================
module arb_sva (
  input logic       clk, rstn,
  input logic       req0, req1,
  input logic [3:0] prio0, prio1,
  input logic       gnt0, gnt1, gnt_valid, gnt_idx, update
);
  default disable iff (!rstn);

  // exactly-one / no-double grant
  ap_mutex: assert property (@(posedge clk) !(gnt0 && gnt1));
  // grant valid iff someone requests
  ap_gv: assert property (@(posedge clk) gnt_valid == (req0 || req1));

  // strict priority honoured: the strictly-higher-priority requester wins
  ap_prio_m0: assert property (@(posedge clk)
    (req0 && req1 && (prio0 > prio1)) |-> gnt0);
  ap_prio_m1: assert property (@(posedge clk)
    (req0 && req1 && (prio1 > prio0)) |-> gnt1);

`ifdef ARB_CHECK_LIVENESS
  // bounded-wait: a continuously-requesting master is granted within N accepts.
  // EXPECTED TO FAIL under strict priority (demonstrates the starvation hazard).
  localparam int MAXW = 64;
  property bounded_wait_m0;
    int n;
    @(posedge clk) (req0, n=0) |-> (req0, n++)[*0:$] ##0 (gnt0 || (n < MAXW));
  endproperty
  ap_live_m0: assert property (bounded_wait_m0)
    else $error("arb_sva: M0 starved (> %0d cycles waiting)", MAXW);
`endif

endmodule : arb_sva
