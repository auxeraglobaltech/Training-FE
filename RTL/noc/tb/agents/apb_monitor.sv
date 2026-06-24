// ============================================================================
//  apb_monitor.sv  —  passive APB monitor
// ----------------------------------------------------------------------------
//  Publishes one apb_seq_item per completed APB transfer (access phase with
//  PREADY high) so the scoreboard can verify the bridge's burst->singles
//  conversion and PSLVERR mapping.
// ============================================================================
class apb_monitor extends uvm_monitor;
  `uvm_component_utils(apb_monitor)

  virtual apb_if #(noc_pkg::ADDR_WIDTH, noc_pkg::DATA_WIDTH, noc_pkg::STRB_WIDTH) vif;
  uvm_analysis_port #(apb_seq_item) ap;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    ap = new("ap", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual apb_if #(noc_pkg::ADDR_WIDTH, noc_pkg::DATA_WIDTH,
        noc_pkg::STRB_WIDTH))::get(this, "", "vif", vif))
      `uvm_fatal("PMON", {"no vif for ", get_full_name()})
  endfunction

  task run_phase(uvm_phase phase);
    forever begin
      @(posedge vif.pclk);
      if (vif.psel && vif.penable && vif.pready) begin
        apb_seq_item t = apb_seq_item::type_id::create("apb");
        t.addr=vif.paddr; t.prot=vif.pprot; t.write=vif.pwrite;
        t.wdata=vif.pwdata; t.strb=vif.pstrb; t.rdata=vif.prdata; t.slverr=vif.pslverr;
        ap.write(t);
      end
    end
  endtask

endclass : apb_monitor
