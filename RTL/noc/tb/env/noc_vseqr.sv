// ============================================================================
//  noc_vseqr.sv  —  virtual sequencer
// ----------------------------------------------------------------------------
//  Holds handles to both master sequencers so a single virtual sequence can
//  coordinate M0 and M1 (e.g. make both storm one slave at the same instant),
//  which uncoordinated parallel sequences cannot reliably produce.
// ============================================================================
class noc_vseqr extends uvm_sequencer;
  `uvm_component_utils(noc_vseqr)

  axi_master_sequencer m0_seqr;
  axi_master_sequencer m1_seqr;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

endclass : noc_vseqr
