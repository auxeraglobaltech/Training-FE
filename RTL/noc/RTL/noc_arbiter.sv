// ============================================================================
//  noc_arbiter.sv  —  2-requester priority + round-robin (strict) arbiter
// ----------------------------------------------------------------------------
//  Decision order:
//    1. exactly one requester  -> grant it
//    2. both, different priority-> grant the higher (strict, can starve)
//    3. both, equal priority    -> round-robin (grant the one NOT served last)
//  Higher prio value = higher priority.  'update' is pulsed by the consumer
//  when it actually accepts a grant, advancing the RR pointer.
//
//  Bug hook NOC_BUG_RR_FREEZE: pointer only advances on a *contended* grant,
//  so an uncontested grant fails to rotate priority (classic RR defect).
// ============================================================================
module noc_arbiter (
  input  logic       clk,
  input  logic       rstn,
  input  logic       req0,
  input  logic       req1,
  input  logic [3:0] prio0,
  input  logic [3:0] prio1,
  input  logic       update,     // pulse when the granted request is consumed
  output logic       gnt0,
  output logic       gnt1,
  output logic       gnt_valid,
  output logic       gnt_idx      // index of the granted requester (0/1)
);

  logic last;            // index of the most recently served requester
  logic       locked;    // a grant is presented downstream, awaiting accept
  logic       lock_idx;  // the locked grantee

  logic       fresh_idx; // freshly computed grantee (when not locked)
  logic       fresh_val;

  // ---- fresh arbitration (priority, then round-robin on a tie) ----
  always_comb begin
    fresh_idx = 1'b0; fresh_val = 1'b0;
    if (req0 && !req1)      begin fresh_idx = 1'b0; fresh_val = 1'b1; end
    else if (req1 && !req0) begin fresh_idx = 1'b1; fresh_val = 1'b1; end
    else if (req0 && req1) begin
      fresh_val = 1'b1;
      if      (prio0 > prio1) fresh_idx = 1'b0;
      else if (prio1 > prio0) fresh_idx = 1'b1;
      else                    fresh_idx = (last == 1'b0) ? 1'b1 : 1'b0;  // RR
    end
  end

  // ---- output: hold a presented grant stable until it is accepted ----
  always_comb begin
    gnt0 = 1'b0; gnt1 = 1'b0;
    if (locked) begin
      gnt_idx   = lock_idx;
      gnt_valid = 1'b1;               // requester holds its valid until accepted
    end else begin
      gnt_idx   = fresh_idx;
      gnt_valid = fresh_val;
    end
    if (gnt_valid) begin
      if (gnt_idx == 1'b0) gnt0 = 1'b1; else gnt1 = 1'b1;
    end
  end

  always_ff @(posedge clk or negedge rstn) begin
    if (!rstn) begin
      last <= 1'b1;                                 // so M0 is favoured first out of reset
      locked <= 1'b0; lock_idx <= 1'b0;
    end else begin
      // grant-lock: capture the presented grant, release on accept
      if (update) locked <= 1'b0;
      else if (gnt_valid && !locked) begin locked <= 1'b1; lock_idx <= gnt_idx; end
      // round-robin pointer update on accepted grant
`ifdef NOC_BUG_RR_FREEZE
      if (update && gnt_valid && req0 && req1)       // BUG: only rotates under contention
        last <= gnt_idx;
`else
      if (update && gnt_valid)                        // correct: rotate on every accepted grant
        last <= gnt_idx;
`endif
    end
  end

endmodule : noc_arbiter
