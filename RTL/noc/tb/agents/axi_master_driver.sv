// ============================================================================
//  axi_master_driver.sv  —  drives the AXI master side (one txn at a time)
// ----------------------------------------------------------------------------
//  Single-outstanding per master (matches the DUT's write contract and keeps
//  the driver simple); concurrency across masters comes from running both
//  master sequencers together under the virtual sequencer.  Full 5-channel
//  AXI4 handshake, INCR bursts.
// ============================================================================
class axi_master_driver extends uvm_driver #(axi_seq_item);
  `uvm_component_utils(axi_master_driver)

  virtual axi_if #(noc_pkg::ADDR_WIDTH, noc_pkg::DATA_WIDTH,
                   noc_pkg::STRB_WIDTH, noc_pkg::ID_WIDTH) vif;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual axi_if #(noc_pkg::ADDR_WIDTH, noc_pkg::DATA_WIDTH,
        noc_pkg::STRB_WIDTH, noc_pkg::ID_WIDTH))::get(this, "", "vif", vif))
      `uvm_fatal("DRV", "no master vif")
  endfunction

  task run_phase(uvm_phase phase);
    drive_idle();
    @(posedge vif.aresetn);
    forever begin
      axi_seq_item tr;
      seq_item_port.get_next_item(tr);
      if (tr.is_write) drive_write(tr);
      else             drive_read(tr);
      seq_item_port.item_done();
    end
  endtask

  task drive_idle();
    vif.awvalid<=0; vif.wvalid<=0; vif.bready<=0; vif.arvalid<=0; vif.rready<=0;
    vif.awid<=0; vif.awaddr<=0; vif.awlen<=0; vif.awsize<=0; vif.awburst<=2'b01;
    vif.awlock<=0; vif.awcache<=0; vif.awprot<=0; vif.awqos<=0;
    vif.wdata<=0; vif.wstrb<=0; vif.wlast<=0;
    vif.arid<=0; vif.araddr<=0; vif.arlen<=0; vif.arsize<=0; vif.arburst<=2'b01;
    vif.arlock<=0; vif.arcache<=0; vif.arprot<=0; vif.arqos<=0;
  endtask

  task drive_write(axi_seq_item tr);
    // AW
    @(posedge vif.aclk);
    vif.awid<=tr.id[noc_pkg::ID_WIDTH-1:0]; vif.awaddr<=tr.addr; vif.awlen<=tr.len;
    vif.awsize<=tr.size; vif.awburst<=tr.burst; vif.awqos<=tr.qos; vif.awvalid<=1'b1;
    do @(posedge vif.aclk); while (!vif.awready);
    vif.awvalid<=1'b0;
    // W beats
    for (int i=0; i<=tr.len; i++) begin
      vif.wdata<=tr.data[i]; vif.wstrb<=tr.strb[i]; vif.wlast<=(i==tr.len); vif.wvalid<=1'b1;
      do @(posedge vif.aclk); while (!vif.wready);
      vif.wvalid<=1'b0; vif.wlast<=1'b0;
    end
    // B
    vif.bready<=1'b1;
    do @(posedge vif.aclk); while (!vif.bvalid);
    tr.resp = vif.bresp;
    vif.bready<=1'b0;
  endtask

  task drive_read(axi_seq_item tr);
    tr.data       = new[tr.len+1];
    tr.rresp_beat = new[tr.len+1];
    // AR
    @(posedge vif.aclk);
    vif.arid<=tr.id[noc_pkg::ID_WIDTH-1:0]; vif.araddr<=tr.addr; vif.arlen<=tr.len;
    vif.arsize<=tr.size; vif.arburst<=tr.burst; vif.arqos<=tr.qos; vif.arvalid<=1'b1;
    do @(posedge vif.aclk); while (!vif.arready);
    vif.arvalid<=1'b0;
    // R beats
    vif.rready<=1'b1;
    for (int i=0; i<=tr.len; i++) begin
      do @(posedge vif.aclk); while (!vif.rvalid);
      tr.data[i]       = vif.rdata;
      tr.rresp_beat[i] = vif.rresp;
      tr.resp          = vif.rresp;
    end
    vif.rready<=1'b0;
  endtask

endclass : axi_master_driver
