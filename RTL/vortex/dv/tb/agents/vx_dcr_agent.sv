// ============================================================
//  DCR agent (active master): sequencer + driver + monitor.
//  Protocol (processor.cpp): write = 1-cycle valid pulse; read = 1-cycle
//  valid with tag in req_data, then wait rsp_valid.
// ============================================================
`ifndef VX_DCR_AGENT_SV
`define VX_DCR_AGENT_SV

class vx_dcr_txn extends uvm_sequence_item;
  rand bit         rw;           // 1 = write
  rand bit [11:0]  addr;
  rand bit [31:0]  data;         // write data / read tag
       bit [31:0]  rsp_data;     // filled by driver on reads

  `uvm_object_utils_begin(vx_dcr_txn)
    `uvm_field_int(rw,       UVM_ALL_ON)
    `uvm_field_int(addr,     UVM_ALL_ON | UVM_HEX)
    `uvm_field_int(data,     UVM_ALL_ON | UVM_HEX)
    `uvm_field_int(rsp_data, UVM_ALL_ON | UVM_HEX)
  `uvm_object_utils_end

  function new(string name = "vx_dcr_txn");
    super.new(name);
  endfunction
endclass

typedef uvm_sequencer #(vx_dcr_txn) vx_dcr_sequencer;

class vx_dcr_driver extends uvm_driver #(vx_dcr_txn);
  `uvm_component_utils(vx_dcr_driver)

  virtual vx_dcr_if vif;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    vif.req_valid <= 1'b0;
    vif.req_rw    <= 1'b0;
    @(negedge vif.reset);
    forever begin
      vx_dcr_txn t;
      seq_item_port.get_next_item(t);
      @(negedge vif.clk);
      vif.req_valid <= 1'b1;
      vif.req_rw    <= t.rw;
      vif.req_addr  <= t.addr;
      vif.req_data  <= t.data;
      @(negedge vif.clk);
      vif.req_valid <= 1'b0;
      vif.req_rw    <= 1'b0;
      if (!t.rw) begin
        while (vif.rsp_valid !== 1'b1) @(negedge vif.clk);
        t.rsp_data = vif.rsp_data;
      end
      seq_item_port.item_done();
    end
  endtask
endclass

class vx_dcr_monitor extends uvm_component;
  `uvm_component_utils(vx_dcr_monitor)

  virtual vx_dcr_if vif;
  uvm_analysis_port #(vx_dcr_txn) ap;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    ap = new("ap", this);
  endfunction

  task run_phase(uvm_phase phase);
    forever begin
      @(posedge vif.clk);
      if (!vif.reset && vif.req_valid) begin
        vx_dcr_txn t = vx_dcr_txn::type_id::create("t");
        t.rw   = vif.req_rw;
        t.addr = vif.req_addr;
        t.data = vif.req_data;
        ap.write(t);
      end
    end
  endtask
endclass

class vx_dcr_agent extends uvm_agent;
  `uvm_component_utils(vx_dcr_agent)

  vx_dcr_sequencer sequencer;
  vx_dcr_driver    driver;
  vx_dcr_monitor   monitor;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    virtual vx_dcr_if vif;
    super.build_phase(phase);
    if (!uvm_config_db#(virtual vx_dcr_if)::get(this, "", "vif", vif))
      `uvm_fatal("DCR_AGT", "no vif")
    sequencer = vx_dcr_sequencer::type_id::create("sequencer", this);
    driver    = vx_dcr_driver::type_id::create("driver", this);
    monitor   = vx_dcr_monitor::type_id::create("monitor", this);
    driver.vif  = vif;
    monitor.vif = vif;
  endfunction

  function void connect_phase(uvm_phase phase);
    driver.seq_item_port.connect(sequencer.seq_item_export);
  endfunction
endclass

`endif
