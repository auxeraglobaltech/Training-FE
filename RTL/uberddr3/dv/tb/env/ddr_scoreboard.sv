// ============================================================================
//  ddr_scoreboard.sv  —  golden-memory scoreboard for the DDR3 controller
// ----------------------------------------------------------------------------
//  Models one 128-bit-word memory keyed by the WB word address. Writes apply
//  byte-selected data to the golden model; reads are compared against it
//  (unwritten locations read 0, matching the model after calibration). Tracks
//  write/read counts and reports a clean PASS/FAIL.
// ============================================================================
class ddr_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(ddr_scoreboard)

  uvm_analysis_imp #(wb_seq_item, ddr_scoreboard) ap_imp;

  bit [127:0] gm [bit [23:0]];   // golden memory
  int n_wr, n_rd, errors;

  function new(string name, uvm_component parent);
    super.new(name,parent); ap_imp = new("ap_imp", this);
  endfunction

  function void write(wb_seq_item t);
    if (t.we) begin
      bit [127:0] cur = gm.exists(t.addr) ? gm[t.addr] : 128'h0;
      for (int b=0; b<16; b++)
        if (t.sel[b]) cur[b*8 +: 8] = t.data[b*8 +: 8];
      gm[t.addr] = cur;
      n_wr++;
    end else begin
      bit [127:0] exp = gm.exists(t.addr) ? gm[t.addr] : 128'h0;
      n_rd++;
      if (t.rdata !== exp) begin
        errors++;
        `uvm_error("SB_DATA", $sformatf("RD addr %h: exp %h got %h", t.addr, exp, t.rdata))
      end
    end
  endfunction

  function void report_phase(uvm_phase phase);
    `uvm_info("SB", $sformatf("writes=%0d reads=%0d errors=%0d", n_wr, n_rd, errors), UVM_LOW)
    if (errors==0) `uvm_info("SB","SCOREBOARD PASSED", UVM_NONE)
    else           `uvm_error("SB", $sformatf("SCOREBOARD FAILED with %0d errors", errors))
  endfunction

endclass : ddr_scoreboard
