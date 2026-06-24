// ============================================================================
//  axi_master_agent.sv  —  active AXI master agent (seqr + driver + monitor)
// ============================================================================
typedef uvm_sequencer #(axi_seq_item) axi_master_sequencer;

class axi_master_agent extends uvm_agent;
  `uvm_component_utils(axi_master_agent)

  axi_master_sequencer seqr;
  axi_master_driver    drv;
  axi_monitor #(noc_pkg::ID_WIDTH) mon;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    seqr = axi_master_sequencer::type_id::create("seqr", this);
    drv  = axi_master_driver::type_id::create("drv", this);
    mon  = axi_monitor #(noc_pkg::ID_WIDTH)::type_id::create("mon", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    drv.seq_item_port.connect(seqr.seq_item_export);
  endfunction

endclass : axi_master_agent
