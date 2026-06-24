// ============================================================================
//  noc_pkg.sv  —  Single source of truth for the 2x2x2 NoC
// ----------------------------------------------------------------------------
//  Holds bus geometry, the address map, the target enum, and the decode()
//  reference function. RTL and (a copy of) the DV scoreboard both rely on the
//  exact same map, so a change here updates routing and checking together.
//
//  Bug-injection hooks (compile-time, OFF by default). Enable on the xrun
//  command line, e.g.  +define+NOC_BUG_DECERR_OMIT
//    NOC_BUG_RR_FREEZE       arbiter pointer not updated on uncontested grant
//    NOC_BUG_PSLVERR_SWALLOW APB PSLVERR reported back as OKAY
//    NOC_BUG_DECERR_OMIT     unmapped access gets no response (fabric hangs)
//    NOC_BUG_BRIDGE_ADDR     bridge uses wrong INCR step for APB burst beats
//    NOC_BUG_BRESP_PERBEAT   write burst emits one B per beat (illegal)
//    NOC_BUG_SAMEID_REORDER  same-ID responses returned out of order
// ============================================================================
package noc_pkg;

  // ----------------------------- Bus geometry -------------------------------
  localparam int unsigned ADDR_WIDTH = 32;
  localparam int unsigned DATA_WIDTH = 32;
  localparam int unsigned STRB_WIDTH = DATA_WIDTH/8;        // 4
  localparam int unsigned ID_WIDTH   = 4;                   // per master

  localparam int unsigned NUM_MASTERS = 2;

  // After ID-remap the fabric prepends the master index to the AXI ID before
  // issuing to S0/S1, so responses (which may return out of order) route back
  // to the correct master.  SLV_ID_WIDTH = ID_WIDTH + clog2(NUM_MASTERS).
  localparam int unsigned MST_IDX_WIDTH = $clog2(NUM_MASTERS);   // 1
  localparam int unsigned SLV_ID_WIDTH  = ID_WIDTH + MST_IDX_WIDTH; // 5

  localparam int unsigned MAX_OUTSTANDING = 8;              // per master

  // ----------------------------- AXI constants ------------------------------
  localparam logic [1:0] AXI_BURST_FIXED = 2'b00;
  localparam logic [1:0] AXI_BURST_INCR  = 2'b01;
  localparam logic [1:0] AXI_BURST_WRAP  = 2'b10;

  localparam logic [1:0] AXI_RESP_OKAY   = 2'b00;
  localparam logic [1:0] AXI_RESP_EXOKAY = 2'b01;
  localparam logic [1:0] AXI_RESP_SLVERR = 2'b10;
  localparam logic [1:0] AXI_RESP_DECERR = 2'b11;

  // ----------------------------- Address map --------------------------------
  // Base / End are inclusive.  Non-overlapping, power-of-two aligned.
  localparam logic [ADDR_WIDTH-1:0] S0_BASE = 32'h0000_0000, S0_END = 32'h0FFF_FFFF;
  localparam logic [ADDR_WIDTH-1:0] S1_BASE = 32'h1000_0000, S1_END = 32'h1FFF_FFFF;
  localparam logic [ADDR_WIDTH-1:0] P0_BASE = 32'h2000_0000, P0_END = 32'h2000_FFFF;
  localparam logic [ADDR_WIDTH-1:0] P1_BASE = 32'h2001_0000, P1_END = 32'h2001_FFFF;

  // ----------------------------- Target enum --------------------------------
  typedef enum logic [2:0] {
    TGT_S0   = 3'd0,
    TGT_S1   = 3'd1,
    TGT_P0   = 3'd2,
    TGT_P1   = 3'd3,
    TGT_NONE = 3'd4    // unmapped -> DECERR
  } target_e;

  // ----------------------------- Decode -------------------------------------
  // Address in -> target out.  TGT_NONE means the DUT must return DECERR.
  function automatic target_e decode(input logic [ADDR_WIDTH-1:0] addr);
    if      (addr >= S0_BASE && addr <= S0_END) decode = TGT_S0;
    else if (addr >= S1_BASE && addr <= S1_END) decode = TGT_S1;
    else if (addr >= P0_BASE && addr <= P0_END) decode = TGT_P0;
    else if (addr >= P1_BASE && addr <= P1_END) decode = TGT_P1;
    else                                        decode = TGT_NONE;
  endfunction

  // True if an INCR burst starting at start_addr would cross a 4 KB boundary.
  // len = AxLEN (beats-1), size_bytes = bytes per beat (2**AxSIZE).
  function automatic logic crosses_4k(input logic [ADDR_WIDTH-1:0] start_addr,
                                      input int unsigned           len,
                                      input int unsigned           size_bytes);
    logic [ADDR_WIDTH-1:0] last_addr;
    last_addr  = start_addr + (((len+1)*size_bytes) - 1);
    crosses_4k = (start_addr[ADDR_WIDTH-1:12] != last_addr[ADDR_WIDTH-1:12]);
  endfunction

  // Is this target reached through the AXI->APB bridge?
  function automatic logic is_apb_target(input target_e t);
    is_apb_target = (t == TGT_P0) || (t == TGT_P1);
  endfunction

endpackage : noc_pkg
