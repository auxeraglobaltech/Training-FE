// ============================================================================
//  axi_slave_responder.sv  —  reactive AXI slave (S0/S1), memory-backed
// ----------------------------------------------------------------------------
//  Single-outstanding per direction, with random READY back-pressure and
//  response latency for realism.  Error injection is OFF by default (so the
//  scoreboard's golden-memory model stays exact); a test can enable SLVERR.
//  IDW = SLV_ID_WIDTH (the remapped 5-bit id); the id is echoed on B/R so the
//  fabric routes the response back to the right master.
// ============================================================================
class axi_slave_responder extends uvm_component;
  `uvm_component_utils(axi_slave_responder)

  virtual axi_if #(noc_pkg::ADDR_WIDTH, noc_pkg::DATA_WIDTH,
                   noc_pkg::STRB_WIDTH, noc_pkg::SLV_ID_WIDTH) vif;

  byte unsigned mem [int];
  int  max_bp  = 3;     // max back-pressure cycles
  int  max_lat = 4;     // max extra response latency
  bit  err_en  = 1'b0;  // inject SLVERR

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual axi_if #(noc_pkg::ADDR_WIDTH, noc_pkg::DATA_WIDTH,
        noc_pkg::STRB_WIDTH, noc_pkg::SLV_ID_WIDTH))::get(this, "", "vif", vif))
      `uvm_fatal("SRESP", {"no vif for ", get_full_name()})
    void'(uvm_config_db#(bit)::get(this, "", "err_en", err_en));
  endfunction

  task run_phase(uvm_phase phase);
    drive_idle();
    @(posedge vif.aresetn);
    fork write_resp(); read_resp(); join
  endtask

  task drive_idle();
    vif.awready<=0; vif.wready<=0; vif.bvalid<=0; vif.bid<=0; vif.bresp<=0;
    vif.arready<=0; vif.rvalid<=0; vif.rid<=0; vif.rdata<=0; vif.rresp<=0; vif.rlast<=0;
  endtask

  task automatic bp();   // random back-pressure
    repeat ($urandom_range(0, max_bp)) @(posedge vif.aclk);
  endtask

  task write_resp();
    forever begin
      bit [noc_pkg::SLV_ID_WIDTH-1:0] id;
      bit [31:0] a; bit [2:0] sz; bit [1:0] bt; bit last;
      // accept AW
      bp(); vif.awready<=1'b1;
      do @(posedge vif.aclk); while (!vif.awvalid);
      id=vif.awid; a=vif.awaddr; sz=vif.awsize; bt=vif.awburst;
      vif.awready<=1'b0;
      // accept W beats
      last=1'b0;
      while (!last) begin
        bp(); vif.wready<=1'b1;
        do @(posedge vif.aclk); while (!vif.wvalid);
        for (int b=0;b<noc_pkg::STRB_WIDTH;b++) if (vif.wstrb[b]) mem[a+b]=vif.wdata[8*b +: 8];
        last=vif.wlast;
        if (bt==noc_pkg::AXI_BURST_INCR) a=a+(1<<sz);
        vif.wready<=1'b0;
      end
      // B
      repeat ($urandom_range(0,max_lat)) @(posedge vif.aclk);
      vif.bid<=id; vif.bresp<=(err_en?noc_pkg::AXI_RESP_SLVERR:noc_pkg::AXI_RESP_OKAY); vif.bvalid<=1'b1;
      do @(posedge vif.aclk); while (!vif.bready);
      vif.bvalid<=1'b0;
    end
  endtask

  task read_resp();
    forever begin
      bit [noc_pkg::SLV_ID_WIDTH-1:0] id;
      bit [31:0] a; bit [7:0] len; bit [2:0] sz; bit [1:0] bt;
      bit [31:0] d;
      // accept AR
      bp(); vif.arready<=1'b1;
      do @(posedge vif.aclk); while (!vif.arvalid);
      id=vif.arid; a=vif.araddr; len=vif.arlen; sz=vif.arsize; bt=vif.arburst;
      vif.arready<=1'b0;
      // R beats
      repeat ($urandom_range(0,max_lat)) @(posedge vif.aclk);
      for (int i=0;i<=len;i++) begin
        d='0;
        for (int b=0;b<noc_pkg::STRB_WIDTH;b++) d[8*b +: 8] = mem.exists(a+b)?mem[a+b]:8'h0;
        vif.rid<=id; vif.rdata<=d;
        vif.rresp<=(err_en?noc_pkg::AXI_RESP_SLVERR:noc_pkg::AXI_RESP_OKAY);
        vif.rlast<=(i==len); vif.rvalid<=1'b1;
        do @(posedge vif.aclk); while (!vif.rready);
        vif.rvalid<=1'b0; vif.rlast<=1'b0;
        if (bt==noc_pkg::AXI_BURST_INCR) a=a+(1<<sz);
      end
    end
  endtask

endclass : axi_slave_responder
