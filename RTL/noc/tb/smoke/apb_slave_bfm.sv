// ============================================================================
//  apb_slave_bfm.sv  —  simple behavioral APB completer (smoke test only)
// ----------------------------------------------------------------------------
//  Memory-backed, zero-wait completer.  Asserts PSLVERR for the magic byte
//  offset 0xE0 so the smoke test can exercise the bridge error path.  Connects
//  via the apb_if.completer modport.  NOT used by the UVM env.
// ============================================================================
`timescale 1ns/1ps
module apb_slave_bfm import noc_pkg::*; (apb_if.completer p);

  byte unsigned mem [int];

  logic [DATA_WIDTH-1:0] rdat;
  always_comb begin
    rdat = '0;
    for (int b=0;b<STRB_WIDTH;b++) rdat[8*b +: 8] = mem.exists(p.paddr+b) ? mem[p.paddr+b] : 8'h0;
  end

  assign p.prdata  = rdat;
  assign p.pready  = p.psel & p.penable;                         // zero wait state
  assign p.pslverr = (p.psel & p.penable) & (p.paddr[7:0] == 8'hE0);

  always_ff @(posedge p.pclk) begin
    if (p.psel && p.penable && p.pready && p.pwrite) begin
      for (int b=0;b<STRB_WIDTH;b++) if (p.pstrb[b]) mem[p.paddr+b] = p.pwdata[8*b +: 8];
    end
  end

endmodule : apb_slave_bfm
