// ============================================================================
//  wb_master_driver.sv  —  drives the native pipelined Wishbone (single-outst.)
// ----------------------------------------------------------------------------
//  Single transaction at a time: assert cyc/stb + payload, hold stb until the
//  request is accepted (stb && !stall), then wait for the completion ack. This
//  is the proven protocol from the Phase-0 BIST. A per-transaction aux tag is
//  assigned for response matching in the monitor.
// ============================================================================
class wb_master_driver extends uvm_driver #(wb_seq_item);
  `uvm_component_utils(wb_master_driver)

  virtual wb_if vif;
  bit [15:0] aux_ctr = 1;

  function new(string name, uvm_component parent); super.new(name,parent); endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual wb_if)::get(this,"","vif",vif))
      `uvm_fatal("DRV","no wb vif")
  endfunction

  task run_phase(uvm_phase phase);
    drive_idle();
    @(posedge vif.rst_n);
    wait (vif.calib_complete === 1'b1);     // never drive before calibration
    forever begin
      wb_seq_item tr;
      seq_item_port.get_next_item(tr);
      drive(tr);
      seq_item_port.item_done();
    end
  endtask

  task drive_idle();
    vif.wb_cyc<=0; vif.wb_stb<=0; vif.wb_we<=0; vif.wb_addr<=0;
    vif.wb_data<=0; vif.wb_sel<=0; vif.aux<=0;
  endtask

  task drive(wb_seq_item tr);
    tr.aux = aux_ctr; aux_ctr++;
    @(posedge vif.clk);
    vif.wb_cyc<=1; vif.wb_stb<=1; vif.wb_we<=tr.we; vif.wb_addr<=tr.addr;
    vif.wb_data<=tr.data; vif.wb_sel<=tr.sel; vif.aux<=tr.aux;
    // hold stb until accepted
    do @(posedge vif.clk); while (vif.wb_stall);
    vif.wb_stb<=0;
    // wait for completion
    do @(posedge vif.clk); while (!vif.wb_ack);
    tr.rdata = vif.wb_rdata;
    tr.err   = vif.wb_err;
    vif.wb_cyc<=0;
  endtask

endclass : wb_master_driver
