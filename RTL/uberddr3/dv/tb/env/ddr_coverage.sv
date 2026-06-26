// ============================================================================
//  ddr_coverage.sv  —  functional coverage for the DDR3 controller
// ----------------------------------------------------------------------------
//  Direction (R/W), bank (from the word address), and byte-select pattern
//  (full / partial / single), crossed direction x bank. Sampled per completed
//  transaction. Enable collection with COV=1.
// ============================================================================
class ddr_coverage extends uvm_subscriber #(wb_seq_item);
  `uvm_component_utils(ddr_coverage)

  // column occupies the low (COL_BITS - clog2(serdes*2)) word-address bits;
  // the bank field sits just above it.
  localparam int COL_OFF = 10 - 3;  // COL_BITS(10) - clog2(8)=3  -> 7

  wb_seq_item tr;
  bit       c_we;
  bit [2:0] c_bank;
  bit [1:0] c_selkind;   // 0=full, 1=partial, 2=single-byte

  covergroup ddr_cg;
    option.per_instance = 1;
    dir_cp  : coverpoint c_we     { bins rd={0}; bins wr={1}; }
    bank_cp : coverpoint c_bank   { bins b[] = {[0:7]}; }
    sel_cp  : coverpoint c_selkind{ bins full={0}; bins partial={1}; bins single={2}; }
    dir_x_bank : cross dir_cp, bank_cp;
  endgroup

  function new(string name, uvm_component parent);
    super.new(name,parent); ddr_cg = new();
  endfunction

  function void write(wb_seq_item t);
    int ones;
    c_we   = t.we;
    // bank bits: low bits of the word address (col is below bank in {row,bank,col})
    c_bank = t.addr[COL_OFF +: 3];
    ones = $countones(t.sel);
    c_selkind = (ones==16) ? 0 : (ones==1) ? 2 : 1;
    ddr_cg.sample();
  endfunction

endclass : ddr_coverage
