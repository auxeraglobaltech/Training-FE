// ============================================================================
//  noc_scoreboard.sv  —  routing-aware scoreboard + golden memory
// ----------------------------------------------------------------------------
//  Two questions per transaction: did it reach the CORRECT target, and was the
//  data correct there?  Reuses noc_pkg::decode() (the single address-map source)
//  to predict the target, models a golden memory per slave for end-to-end data,
//  and checks responses (OKAY / SLVERR / DECERR).  It accepts any legal
//  arbitration interleaving — only per-master correctness is asserted here;
//  fairness/priority live in the SVA layer.
//
//  Analysis imports:
//    _m0/_m1 : completed master transactions (full burst + response)
//    _s0/_s1 : arrivals at the AXI slave ports (routing confirmation)
//    _p0/_p1 : APB transfers seen by the bridge (routing + bridge sanity)
// ============================================================================
`uvm_analysis_imp_decl(_m0)
`uvm_analysis_imp_decl(_m1)
`uvm_analysis_imp_decl(_s0)
`uvm_analysis_imp_decl(_s1)
`uvm_analysis_imp_decl(_p0)
`uvm_analysis_imp_decl(_p1)

class noc_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(noc_scoreboard)

  uvm_analysis_imp_m0 #(axi_seq_item, noc_scoreboard) m0_imp;
  uvm_analysis_imp_m1 #(axi_seq_item, noc_scoreboard) m1_imp;
  uvm_analysis_imp_s0 #(axi_seq_item, noc_scoreboard) s0_imp;
  uvm_analysis_imp_s1 #(axi_seq_item, noc_scoreboard) s1_imp;
  uvm_analysis_imp_p0 #(apb_seq_item, noc_scoreboard) p0_imp;
  uvm_analysis_imp_p1 #(apb_seq_item, noc_scoreboard) p1_imp;

  // golden memory per target
  byte unsigned gm [noc_pkg::target_e][int];

  // a test can declare a target's responses are expected to be SLVERR
  // (e.g. APB PSLVERR injection); read-data is then not checked for it.
  bit expect_err [noc_pkg::target_e];

  int n_wr, n_rd, n_decerr, n_arr_s0, n_arr_s1, n_arr_p0, n_arr_p1;
  int errors;

  // per-master, per-target completion counts (for arbitration fairness checks)
  int mcnt [2][noc_pkg::target_e];

  // fairness check: master-0 share of completions to 'tgt' must lie in band
  function real share_m0(noc_pkg::target_e tgt);
    int tot = mcnt[0][tgt] + mcnt[1][tgt];
    return (tot == 0) ? 0.0 : real'(mcnt[0][tgt]) / real'(tot);
  endfunction

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    m0_imp=new("m0_imp",this); m1_imp=new("m1_imp",this);
    s0_imp=new("s0_imp",this); s1_imp=new("s1_imp",this);
    p0_imp=new("p0_imp",this); p1_imp=new("p1_imp",this);
  endfunction

  // ---- master transactions ----
  function void write_m0(axi_seq_item t); check_master("M0", 0, t); endfunction
  function void write_m1(axi_seq_item t); check_master("M1", 1, t); endfunction

  function void check_master(string m, int midx, axi_seq_item t);
    noc_pkg::target_e tgt = noc_pkg::decode(t.addr);
    mcnt[midx][tgt]++;
    if (tgt == noc_pkg::TGT_NONE) begin
      n_decerr++;
      if (t.resp !== noc_pkg::AXI_RESP_DECERR) begin
        errors++; `uvm_error("SB_DECERR", $sformatf("%s %s addr %h: expected DECERR, got resp %0d",
                   m, t.is_write?"WR":"RD", t.addr, t.resp))
      end
      return;
    end
    if (t.is_write) begin
      bit [1:0] exp = expect_err[tgt] ? noc_pkg::AXI_RESP_SLVERR : noc_pkg::AXI_RESP_OKAY;
      n_wr++;
      apply_write(tgt, t);
      if (t.resp !== exp) begin
        errors++; `uvm_error("SB_WRESP", $sformatf("%s WR addr %h tgt %s: resp %0d != exp %0d",
                   m, t.addr, tgt.name(), t.resp, exp))
      end
    end else begin
      n_rd++;
      if (expect_err[tgt]) begin            // error target: only check the response, not data
        if (t.resp !== noc_pkg::AXI_RESP_SLVERR) begin
          errors++; `uvm_error("SB_RRESP", $sformatf("%s RD addr %h tgt %s: resp %0d != SLVERR",
                     m, t.addr, tgt.name(), t.resp))
        end
      end else begin
        check_read(m, tgt, t);
      end
    end
  endfunction

  function void apply_write(noc_pkg::target_e tgt, axi_seq_item t);
    bit [31:0] a = t.addr;
    foreach (t.data[i]) begin
      for (int b=0;b<noc_pkg::STRB_WIDTH;b++)
        if (t.strb[i][b]) gm[tgt][a+b] = t.data[i][8*b +: 8];
      a += (1 << t.size);
    end
  endfunction

  function void check_read(string m, noc_pkg::target_e tgt, axi_seq_item t);
    bit [31:0] a = t.addr;
    foreach (t.data[i]) begin
      bit [31:0] exp = '0;
      for (int b=0;b<noc_pkg::STRB_WIDTH;b++)
        exp[8*b +: 8] = gm[tgt].exists(a+b) ? gm[tgt][a+b] : 8'h0;
      if (t.data[i] !== exp) begin
        errors++; `uvm_error("SB_DATA", $sformatf("%s RD addr %h beat %0d tgt %s: exp %h got %h",
                   m, t.addr, i, tgt.name(), exp, t.data[i]))
      end
      a += (1 << t.size);
    end
    if (t.resp !== noc_pkg::AXI_RESP_OKAY) begin
      errors++; `uvm_error("SB_RRESP", $sformatf("%s RD addr %h tgt %s: resp %0d != OKAY",
                 m, t.addr, tgt.name(), t.resp))
    end
  endfunction

  // ---- slave arrivals (routing check) ----
  function void write_s0(axi_seq_item t); check_arrival(noc_pkg::TGT_S0, t.addr); n_arr_s0++; endfunction
  function void write_s1(axi_seq_item t); check_arrival(noc_pkg::TGT_S1, t.addr); n_arr_s1++; endfunction
  function void write_p0(apb_seq_item t); check_arrival(noc_pkg::TGT_P0, t.addr); n_arr_p0++; endfunction
  function void write_p1(apb_seq_item t); check_arrival(noc_pkg::TGT_P1, t.addr); n_arr_p1++; endfunction

  function void check_arrival(noc_pkg::target_e where, bit [31:0] a);
    if (noc_pkg::decode(a) != where) begin
      errors++; `uvm_error("SB_ROUTE", $sformatf("Transaction addr %h arrived at %s but decodes to %s (mis-route)",
                 a, where.name(), noc_pkg::decode(a).name()))
    end
  endfunction

  function void report_phase(uvm_phase phase);
    `uvm_info("SB", $sformatf("writes=%0d reads=%0d decerr=%0d arrivals[s0=%0d s1=%0d p0=%0d p1=%0d] errors=%0d",
              n_wr, n_rd, n_decerr, n_arr_s0, n_arr_s1, n_arr_p0, n_arr_p1, errors), UVM_LOW)
    if (errors == 0) `uvm_info("SB", "SCOREBOARD PASSED", UVM_NONE)
    else             `uvm_error("SB", $sformatf("SCOREBOARD FAILED with %0d errors", errors))
  endfunction

endclass : noc_scoreboard
