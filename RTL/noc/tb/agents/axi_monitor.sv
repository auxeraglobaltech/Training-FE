// ============================================================================
//  axi_monitor.sv  —  passive AXI monitor (parameterised by ID width)
// ----------------------------------------------------------------------------
//  Reconstructs completed AXI transactions from the bus and publishes them on
//  an analysis port.  Used on master ports (IDW=4) and on the AXI slave ports
//  (IDW=5, remapped id).  Writes and reads are tracked independently; a write
//  completes on its B, a read on its last R beat.
//
//  Single-outstanding-per-direction is assumed (the driver is single
//  outstanding and the DUT issues at most one write/one read per master port),
//  which keeps the monitor simple and exact.
// ============================================================================
class axi_monitor #(parameter int IDW = 4) extends uvm_monitor;
  `uvm_component_param_utils(axi_monitor#(IDW))

  virtual axi_if #(noc_pkg::ADDR_WIDTH, noc_pkg::DATA_WIDTH, noc_pkg::STRB_WIDTH, IDW) vif;
  uvm_analysis_port #(axi_seq_item) ap;
  string tag = "AXIMON";

  function new(string name, uvm_component parent);
    super.new(name, parent);
    ap = new("ap", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual axi_if #(noc_pkg::ADDR_WIDTH, noc_pkg::DATA_WIDTH,
        noc_pkg::STRB_WIDTH, IDW))::get(this, "", "vif", vif))
      `uvm_fatal("MON", {"no vif for ", get_full_name()})
    void'(uvm_config_db#(string)::get(this, "", "tag", tag));
  endfunction

  task run_phase(uvm_phase phase);
    fork
      mon_write();
      mon_read();
    join
  endtask

  // ---- Write: capture AW, collect W beats, complete on B ----
  task mon_write();
    forever begin
      axi_seq_item tr;
      @(posedge vif.aclk);
      if (vif.awvalid && vif.awready) begin
        tr = axi_seq_item::type_id::create("wr");
        tr.is_write = 1'b1;
        tr.id = vif.awid; tr.addr = vif.awaddr; tr.len = vif.awlen;
        tr.size = vif.awsize; tr.burst = vif.awburst; tr.qos = vif.awqos;
        tr.data = new[tr.len+1]; tr.strb = new[tr.len+1];
        // collect W beats
        begin int i = 0;
          while (i <= tr.len) begin
            @(posedge vif.aclk);
            if (vif.wvalid && vif.wready) begin
              tr.data[i] = vif.wdata; tr.strb[i] = vif.wstrb; i++;
            end
          end
        end
        // wait B
        forever begin
          @(posedge vif.aclk);
          if (vif.bvalid && vif.bready) begin tr.resp = vif.bresp; break; end
        end
        ap.write(tr);
      end
    end
  endtask

  // ---- Read: capture AR, collect R beats (complete on rlast) ----
  task mon_read();
    forever begin
      axi_seq_item tr;
      @(posedge vif.aclk);
      if (vif.arvalid && vif.arready) begin
        tr = axi_seq_item::type_id::create("rd");
        tr.is_write = 1'b0;
        tr.id = vif.arid; tr.addr = vif.araddr; tr.len = vif.arlen;
        tr.size = vif.arsize; tr.burst = vif.arburst; tr.qos = vif.arqos;
        tr.data = new[tr.len+1]; tr.rresp_beat = new[tr.len+1];
        begin int i = 0;
          while (i <= tr.len) begin
            @(posedge vif.aclk);
            if (vif.rvalid && vif.rready) begin
              tr.data[i] = vif.rdata; tr.rresp_beat[i] = vif.rresp; tr.resp = vif.rresp; i++;
            end
          end
        end
        ap.write(tr);
      end
    end
  endtask

endclass : axi_monitor
