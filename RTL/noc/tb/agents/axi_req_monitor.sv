// ============================================================================
//  axi_req_monitor.sv  —  slave-side arrival monitor (request side only)
// ----------------------------------------------------------------------------
//  On every AW/AR handshake at an AXI slave port it publishes a minimal item
//  (addr, is_write) so the scoreboard can confirm the transaction landed on the
//  correct slave (routing check) and that no slave is reached for an unmapped
//  address.  Request-side only, so it is robust to multi-outstanding / OOO
//  reads that a full burst reconstruction could not track.
// ============================================================================
class axi_req_monitor extends uvm_monitor;
  `uvm_component_utils(axi_req_monitor)

  virtual axi_if #(noc_pkg::ADDR_WIDTH, noc_pkg::DATA_WIDTH,
                   noc_pkg::STRB_WIDTH, noc_pkg::SLV_ID_WIDTH) vif;
  uvm_analysis_port #(axi_seq_item) ap;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    ap = new("ap", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual axi_if #(noc_pkg::ADDR_WIDTH, noc_pkg::DATA_WIDTH,
        noc_pkg::STRB_WIDTH, noc_pkg::SLV_ID_WIDTH))::get(this, "", "vif", vif))
      `uvm_fatal("REQMON", {"no vif for ", get_full_name()})
  endfunction

  task run_phase(uvm_phase phase);
    forever begin
      @(posedge vif.aclk);
      if (vif.awvalid && vif.awready) publish(vif.awaddr, 1'b1, vif.awid);
      if (vif.arvalid && vif.arready) publish(vif.araddr, 1'b0, vif.arid);
    end
  endtask

  function void publish(bit [31:0] a, bit wr, bit [noc_pkg::SLV_ID_WIDTH-1:0] sid);
    axi_seq_item t = axi_seq_item::type_id::create("arr");
    t.addr = a; t.is_write = wr; t.id = sid;   // sid carries {master_idx, orig_id}
    ap.write(t);
  endfunction

endclass : axi_req_monitor
