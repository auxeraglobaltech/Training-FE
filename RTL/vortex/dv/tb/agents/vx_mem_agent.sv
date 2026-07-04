// ============================================================
//  Memory agent (reactive slave). One agent instance per DUT memory bank.
//
//  - vx_mem_model:     shared sparse byte memory + hex loader (config_db
//                      singleton, shared by all banks and the scoreboard)
//  - vx_mem_responder: services requests with fixed latency (the protocol
//                      proven in tb_top_vx_smoke)
//  - vx_mem_monitor:   publishes every accepted request as vx_mem_txn
// ============================================================
`ifndef VX_MEM_AGENT_SV
`define VX_MEM_AGENT_SV

// ---------------- shared backing store ----------------
class vx_mem_model extends uvm_object;
  `uvm_object_utils(vx_mem_model)

  logic [7:0]      mem [longint unsigned];
  longint unsigned n_rd = 0, n_wr = 0;

  function new(string name = "vx_mem_model");
    super.new(name);
  endfunction

  function void load_hex(string path);
    $readmemh(path, mem);
    `uvm_info("MEM_MODEL", $sformatf("loaded image: %s", path), UVM_LOW)
  endfunction

  function logic [7:0] rd_byte(longint unsigned a);
    return mem.exists(a) ? mem[a] : 8'h00;
  endfunction

  function logic [31:0] rd_word(longint unsigned a);
    logic [31:0] w;
    for (int i = 0; i < 4; i++) w[i*8 +: 8] = rd_byte(a + i);
    return w;
  endfunction
endclass

// ---------------- transaction ----------------
class vx_mem_txn extends uvm_sequence_item;
  bit                 rw;          // 1 = write
  int unsigned        bank;
  longint unsigned    byte_addr;   // reconstructed global byte address
  logic [`VX_MEM_DATA_SIZE*8-1:0] data;
  logic [`VX_MEM_DATA_SIZE-1:0]   byteen;
  logic [63:0]        tag;

  `uvm_object_utils_begin(vx_mem_txn)
    `uvm_field_int(rw,        UVM_ALL_ON)
    `uvm_field_int(bank,      UVM_ALL_ON)
    `uvm_field_int(byte_addr, UVM_ALL_ON | UVM_HEX)
    `uvm_field_int(tag,       UVM_ALL_ON | UVM_HEX)
  `uvm_object_utils_end

  function new(string name = "vx_mem_txn");
    super.new(name);
  endfunction
endclass

// ---------------- responder (reactive driver, no sequencer) ----------------
class vx_mem_responder extends uvm_component;
  `uvm_component_utils(vx_mem_responder)

  virtual vx_mem_if vif;
  vx_mem_model      model;
  int unsigned      bank_id;
  int unsigned      num_banks;
  int unsigned      rsp_latency = 4;

  typedef struct {
    logic [`VX_MEM_DATA_SIZE*8-1:0] data;
    logic [63:0]                    tag;
    longint unsigned                due;
  } rsp_t;
  rsp_t rsp_q [$];
  longint unsigned cycle = 0;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    vif.req_ready <= 1'b0;
    vif.rsp_valid <= 1'b0;
    @(negedge vif.reset);
    forever begin
      @(posedge vif.clk);
      cycle++;
      vif.req_ready <= 1'b1;
      // request side
      if (vif.req_valid && vif.req_ready) begin
        longint unsigned byte_addr;
        // INTERLEAVE=1 reconstruction (processor.cpp)
        byte_addr = (longint'(vif.req_addr) * num_banks + bank_id)
                    * `VX_MEM_DATA_SIZE;
        if (vif.req_rw) begin
          model.n_wr++;
          for (int i = 0; i < `VX_MEM_DATA_SIZE; i++)
            if (vif.req_byteen[i])
              model.mem[byte_addr + i] = vif.req_data[i*8 +: 8];
        end else begin
          rsp_t r;
          model.n_rd++;
          for (int i = 0; i < `VX_MEM_DATA_SIZE; i++)
            r.data[i*8 +: 8] = model.rd_byte(byte_addr + i);
          r.tag = vif.req_tag;
          r.due = cycle + rsp_latency;
          rsp_q.push_back(r);
        end
      end
      // response side (in-order, hold until accepted)
      if (vif.rsp_valid && vif.rsp_ready)
        vif.rsp_valid <= 1'b0;
      if (!(vif.rsp_valid && !vif.rsp_ready)) begin
        if (rsp_q.size() > 0 && rsp_q[0].due <= cycle) begin
          vif.rsp_valid <= 1'b1;
          vif.rsp_data  <= rsp_q[0].data;
          vif.rsp_tag   <= rsp_q[0].tag;
          void'(rsp_q.pop_front());
        end
      end
    end
  endtask
endclass

// ---------------- monitor ----------------
class vx_mem_monitor extends uvm_component;
  `uvm_component_utils(vx_mem_monitor)

  virtual vx_mem_if vif;
  int unsigned      bank_id;
  int unsigned      num_banks;
  uvm_analysis_port #(vx_mem_txn) ap;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    ap = new("ap", this);
  endfunction

  task run_phase(uvm_phase phase);
    forever begin
      @(posedge vif.clk);
      if (!vif.reset && vif.req_valid && vif.req_ready) begin
        vx_mem_txn t = vx_mem_txn::type_id::create("t");
        t.rw        = vif.req_rw;
        t.bank      = bank_id;
        t.byte_addr = (longint'(vif.req_addr) * num_banks + bank_id)
                      * `VX_MEM_DATA_SIZE;
        t.data      = vif.req_data;
        t.byteen    = vif.req_byteen;
        t.tag       = vif.req_tag;
        ap.write(t);
      end
    end
  endtask
endclass

// ---------------- agent ----------------
class vx_mem_agent extends uvm_agent;
  `uvm_component_utils(vx_mem_agent)

  vx_mem_responder responder;
  vx_mem_monitor   monitor;
  int unsigned     bank_id;
  int unsigned     num_banks;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    virtual vx_mem_if vif;
    vx_mem_model      model;
    super.build_phase(phase);
    if (!uvm_config_db#(virtual vx_mem_if)::get(this, "", "vif", vif))
      `uvm_fatal("MEM_AGT", {"no vif for ", get_full_name()})
    if (!uvm_config_db#(vx_mem_model)::get(this, "", "mem_model", model))
      `uvm_fatal("MEM_AGT", "no mem_model")
    void'(uvm_config_db#(int unsigned)::get(this, "", "bank_id", bank_id));
    void'(uvm_config_db#(int unsigned)::get(this, "", "num_banks", num_banks));
    responder = vx_mem_responder::type_id::create("responder", this);
    monitor   = vx_mem_monitor::type_id::create("monitor", this);
    responder.vif = vif;         responder.model = model;
    responder.bank_id = bank_id; responder.num_banks = num_banks;
    monitor.vif = vif;
    monitor.bank_id = bank_id;   monitor.num_banks = num_banks;
  endfunction
endclass

`endif
