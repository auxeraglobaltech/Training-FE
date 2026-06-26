// ============================================================================
//  wb_monitor.sv  —  passive Wishbone monitor
// ----------------------------------------------------------------------------
//  Captures each accepted request (stb && !stall) into an in-order queue, then
//  pairs it with the next ack (o_wb_ack), filling read data, and publishes the
//  completed transaction on an analysis port. Pipelined acks return in order
//  for this controller, so FIFO matching is exact.
// ============================================================================
class wb_monitor extends uvm_monitor;
  `uvm_component_utils(wb_monitor)

  virtual wb_if vif;
  uvm_analysis_port #(wb_seq_item) ap;
  wb_seq_item pend[$];

  function new(string name, uvm_component parent);
    super.new(name,parent); ap = new("ap", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual wb_if)::get(this,"","vif",vif))
      `uvm_fatal("MON","no wb vif")
  endfunction

  task run_phase(uvm_phase phase);
    forever begin
      @(posedge vif.clk);
      if (!vif.rst_n) continue;
      // capture accepted request
      if (vif.wb_cyc && vif.wb_stb && !vif.wb_stall) begin
        wb_seq_item t = wb_seq_item::type_id::create("req");
        t.we=vif.wb_we; t.addr=vif.wb_addr; t.data=vif.wb_data; t.sel=vif.wb_sel; t.aux=vif.aux;
        pend.push_back(t);
      end
      // complete on ack
      if (vif.wb_ack && pend.size() > 0) begin
        wb_seq_item t = pend.pop_front();
        t.rdata = vif.wb_rdata;
        t.err   = vif.wb_err;
        ap.write(t);
      end
    end
  endtask

endclass : wb_monitor
