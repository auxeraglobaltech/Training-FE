// ============================================================================
//  wb_master_agent.sv  —  active Wishbone master agent
// ============================================================================
typedef uvm_sequencer #(wb_seq_item) wb_sequencer;

class wb_master_agent extends uvm_agent;
  `uvm_component_utils(wb_master_agent)

  wb_sequencer      seqr;
  wb_master_driver  drv;
  wb_monitor        mon;

  function new(string name, uvm_component parent); super.new(name,parent); endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    seqr = wb_sequencer::type_id::create("seqr", this);
    drv  = wb_master_driver::type_id::create("drv", this);
    mon  = wb_monitor::type_id::create("mon", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    drv.seq_item_port.connect(seqr.seq_item_export);
  endfunction

endclass : wb_master_agent
