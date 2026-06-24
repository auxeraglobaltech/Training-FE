// ============================================================================
//  apb_slave_responder.sv  —  reactive APB completer (P0/P1), memory-backed
// ----------------------------------------------------------------------------
//  Drives PREADY/PRDATA/PSLVERR.  Random wait states optional.  PSLVERR is OFF
//  by default; a test enables err_en to exercise the bridge's PSLVERR->SLVERR
//  path.  APB is single, in-order — exactly what the bridge presents.
// ============================================================================
class apb_slave_responder extends uvm_component;
  `uvm_component_utils(apb_slave_responder)

  virtual apb_if #(noc_pkg::ADDR_WIDTH, noc_pkg::DATA_WIDTH, noc_pkg::STRB_WIDTH) vif;

  byte unsigned mem [int];
  int  max_ws = 2;      // max wait states
  bit  err_en = 1'b0;   // assert PSLVERR

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual apb_if #(noc_pkg::ADDR_WIDTH, noc_pkg::DATA_WIDTH,
        noc_pkg::STRB_WIDTH))::get(this, "", "vif", vif))
      `uvm_fatal("PRESP", {"no vif for ", get_full_name()})
    void'(uvm_config_db#(bit)::get(this, "", "err_en", err_en));
  endfunction

  task run_phase(uvm_phase phase);
    vif.pready<=0; vif.prdata<=0; vif.pslverr<=0;
    @(posedge vif.presetn);
    forever begin
      bit [31:0] d;
      @(posedge vif.pclk);
      // setup phase: psel=1, penable=0
      if (vif.psel && !vif.penable) begin
        // wait for access phase
        do @(posedge vif.pclk); while (!(vif.psel && vif.penable));
        repeat ($urandom_range(0, max_ws)) begin
          vif.pready<=1'b0; @(posedge vif.pclk);
        end
        if (vif.pwrite) begin
          for (int b=0;b<noc_pkg::STRB_WIDTH;b++) if (vif.pstrb[b]) mem[vif.paddr+b]=vif.pwdata[8*b +: 8];
          d = '0;
        end else begin
          d = '0;
          for (int b=0;b<noc_pkg::STRB_WIDTH;b++) d[8*b +: 8] = mem.exists(vif.paddr+b)?mem[vif.paddr+b]:8'h0;
        end
        vif.prdata  <= d;
        vif.pslverr <= err_en;
        vif.pready  <= 1'b1;
        @(posedge vif.pclk);
        vif.pready  <= 1'b0;
        vif.pslverr <= 1'b0;
      end
    end
  endtask

endclass : apb_slave_responder
