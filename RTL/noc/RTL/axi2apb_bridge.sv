// ============================================================================
//  axi2apb_bridge.sv  —  AXI -> APB protocol converter for one APB slave
// ----------------------------------------------------------------------------
//  Arbitrates the two masters, then serialises one transaction at a time onto
//  APB (APB is single, in-order).  An N-beat AXI burst becomes N APB single
//  transfers with incrementing addresses; a write burst returns exactly one B
//  (aggregating any PSLVERR -> SLVERR); each read beat carries its transfer's
//  RRESP.  Writes are chosen before reads when both are pending.
//
//  Bug hooks:
//    NOC_BUG_PSLVERR_SWALLOW  APB error not propagated (reports OKAY)
//    NOC_BUG_BRIDGE_ADDR      APB beat address not incremented (all same addr)
//    NOC_BUG_BRESP_PERBEAT    one B per beat instead of one per burst
// ============================================================================
module axi2apb_bridge
  import noc_pkg::*;
(
  input  logic                  aclk,
  input  logic                  aresetn,

  // ---- master-facing (valids pre-gated to this target by the fabric) ----
  input  logic [ID_WIDTH-1:0]   m_awid    [NUM_MASTERS],
  input  logic [ADDR_WIDTH-1:0] m_awaddr  [NUM_MASTERS],
  input  logic [7:0]            m_awlen   [NUM_MASTERS],
  input  logic [2:0]            m_awsize  [NUM_MASTERS],
  input  logic [1:0]            m_awburst [NUM_MASTERS],
  input  logic [2:0]            m_awprot  [NUM_MASTERS],
  input  logic [3:0]            m_awqos   [NUM_MASTERS],
  input  logic                  m_awvalid [NUM_MASTERS],
  output logic                  m_awready [NUM_MASTERS],
  input  logic [DATA_WIDTH-1:0] m_wdata   [NUM_MASTERS],
  input  logic [STRB_WIDTH-1:0] m_wstrb   [NUM_MASTERS],
  input  logic                  m_wlast   [NUM_MASTERS],
  input  logic                  m_wvalid  [NUM_MASTERS],
  output logic                  m_wready  [NUM_MASTERS],
  output logic [ID_WIDTH-1:0]   m_bid     [NUM_MASTERS],
  output logic [1:0]            m_bresp   [NUM_MASTERS],
  output logic                  m_bvalid  [NUM_MASTERS],
  input  logic                  m_bready  [NUM_MASTERS],

  input  logic [ID_WIDTH-1:0]   m_arid    [NUM_MASTERS],
  input  logic [ADDR_WIDTH-1:0] m_araddr  [NUM_MASTERS],
  input  logic [7:0]            m_arlen   [NUM_MASTERS],
  input  logic [2:0]            m_arsize  [NUM_MASTERS],
  input  logic [1:0]            m_arburst [NUM_MASTERS],
  input  logic [2:0]            m_arprot  [NUM_MASTERS],
  input  logic [3:0]            m_arqos   [NUM_MASTERS],
  input  logic                  m_arvalid [NUM_MASTERS],
  output logic                  m_arready [NUM_MASTERS],
  output logic [ID_WIDTH-1:0]   m_rid     [NUM_MASTERS],
  output logic [DATA_WIDTH-1:0] m_rdata   [NUM_MASTERS],
  output logic [1:0]            m_rresp   [NUM_MASTERS],
  output logic                  m_rlast   [NUM_MASTERS],
  output logic                  m_rvalid  [NUM_MASTERS],
  input  logic                  m_rready  [NUM_MASTERS],

  // ---- APB requester port ----
  output logic [ADDR_WIDTH-1:0] p_paddr,
  output logic [2:0]            p_pprot,
  output logic                  p_psel,
  output logic                  p_penable,
  output logic                  p_pwrite,
  output logic [DATA_WIDTH-1:0] p_pwdata,
  output logic [STRB_WIDTH-1:0] p_pstrb,
  input  logic [DATA_WIDTH-1:0] p_prdata,
  input  logic                  p_pready,
  input  logic                  p_pslverr
);

  typedef enum logic [3:0] {
    B_IDLE, B_WBEAT, B_WSETUP, B_WACCESS, B_WRESP,
            B_RSETUP, B_RACCESS, B_RBEAT
  } st_e;
  st_e st;

  logic                 sel;         // selected master
  logic [ID_WIDTH-1:0]  id;          // original AXI id (for B/R)
  logic [ADDR_WIDTH-1:0]addr;        // current beat address
  logic [2:0]           pprot_l;
  logic                 incr;        // INCR burst -> increment address
  logic [ADDR_WIDTH-1:0]step;        // bytes per beat (2**size)
  logic [7:0]           rbeat;       // read beats remaining (counts down from arlen)
  logic                 werr;        // accumulated write error
  logic [DATA_WIDTH-1:0]wd_l;        // captured write data
  logic [STRB_WIDTH-1:0]ws_l;        // captured write strobe
  logic                 wlast_l;     // captured write last
  logic [DATA_WIDTH-1:0]rd_l;        // captured read data
  logic                 rerr_l;      // captured read error

  // ---- arbiters: writes and reads ----
  logic w_g0,w_g1,w_gv,w_gidx,w_upd;
  logic r_g0,r_g1,r_gv,r_gidx,r_upd;
  noc_arbiter u_warb (.clk(aclk), .rstn(aresetn), .req0(m_awvalid[0]), .req1(m_awvalid[1]),
                      .prio0(m_awqos[0]), .prio1(m_awqos[1]), .update(w_upd),
                      .gnt0(w_g0), .gnt1(w_g1), .gnt_valid(w_gv), .gnt_idx(w_gidx));
  noc_arbiter u_rarb (.clk(aclk), .rstn(aresetn), .req0(m_arvalid[0]), .req1(m_arvalid[1]),
                      .prio0(m_arqos[0]), .prio1(m_arqos[1]), .update(r_upd),
                      .gnt0(r_g0), .gnt1(r_g1), .gnt_valid(r_gv), .gnt_idx(r_gidx));

  // -------------------------------------------------------------------------
  //  Combinational outputs
  // -------------------------------------------------------------------------
  always_comb begin
    for (int i = 0; i < NUM_MASTERS; i++) begin
      m_awready[i] = 1'b0; m_wready[i] = 1'b0;
      m_bvalid[i]  = 1'b0; m_bid[i] = id; m_bresp[i] = '0;
      m_arready[i] = 1'b0;
      m_rvalid[i]  = 1'b0; m_rid[i] = id; m_rdata[i] = '0; m_rresp[i] = '0; m_rlast[i] = 1'b0;
    end
    p_paddr = addr; p_pprot = pprot_l; p_psel = 1'b0; p_penable = 1'b0;
    p_pwrite = 1'b0; p_pwdata = wd_l; p_pstrb = ws_l;
    w_upd = 1'b0; r_upd = 1'b0;

    unique case (st)
      B_IDLE: begin
        if (w_gv) begin
          m_awready[w_gidx] = 1'b1;   // accept AW
          w_upd             = 1'b1;
        end else if (r_gv) begin
          m_arready[r_gidx] = 1'b1;   // accept AR
          r_upd             = 1'b1;
        end
      end
      B_WBEAT:  m_wready[sel] = 1'b1;  // capture one write beat
      B_WSETUP: begin p_psel = 1'b1; p_penable = 1'b0; p_pwrite = 1'b1; end
      B_WACCESS:begin p_psel = 1'b1; p_penable = 1'b1; p_pwrite = 1'b1; end
      B_WRESP: begin
        m_bvalid[sel] = 1'b1;
        m_bid[sel]    = id;
        m_bresp[sel]  = werr ? AXI_RESP_SLVERR : AXI_RESP_OKAY;
      end
      B_RSETUP: begin p_psel = 1'b1; p_penable = 1'b0; p_pwrite = 1'b0; end
      B_RACCESS:begin p_psel = 1'b1; p_penable = 1'b1; p_pwrite = 1'b0; end
      B_RBEAT: begin
        m_rvalid[sel] = 1'b1;
        m_rid[sel]    = id;
        m_rdata[sel]  = rd_l;
        m_rresp[sel]  = rerr_l ? AXI_RESP_SLVERR : AXI_RESP_OKAY;
        m_rlast[sel]  = (rbeat == 8'd0);
      end
      default: ;
    endcase
  end

  // -------------------------------------------------------------------------
  //  Sequential
  // -------------------------------------------------------------------------
  always_ff @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
      st <= B_IDLE; sel <= 1'b0; id <= '0; addr <= '0; pprot_l <= '0;
      incr <= 1'b0; step <= '0; rbeat <= '0; werr <= 1'b0;
      wd_l <= '0; ws_l <= '0; wlast_l <= 1'b0; rd_l <= '0; rerr_l <= 1'b0;
    end else case (st)
      B_IDLE: begin
        if (w_gv) begin
          sel <= w_gidx; id <= m_awid[w_gidx]; addr <= m_awaddr[w_gidx];
          pprot_l <= m_awprot[w_gidx]; incr <= (m_awburst[w_gidx] == AXI_BURST_INCR);
          step <= (32'd1 << m_awsize[w_gidx]); werr <= 1'b0; st <= B_WBEAT;
        end else if (r_gv) begin
          sel <= r_gidx; id <= m_arid[r_gidx]; addr <= m_araddr[r_gidx];
          pprot_l <= m_arprot[r_gidx]; incr <= (m_arburst[r_gidx] == AXI_BURST_INCR);
          step <= (32'd1 << m_arsize[r_gidx]); rbeat <= m_arlen[r_gidx]; st <= B_RSETUP;
        end
      end

      // ---- write: capture a beat, run an APB write transfer ----
      B_WBEAT: if (m_wvalid[sel]) begin
                 wd_l <= m_wdata[sel]; ws_l <= m_wstrb[sel]; wlast_l <= m_wlast[sel];
                 st <= B_WSETUP;
               end
      B_WSETUP: st <= B_WACCESS;
      B_WACCESS: if (p_pready) begin
`ifndef NOC_BUG_PSLVERR_SWALLOW
                   werr <= werr | p_pslverr;
`endif
`ifndef NOC_BUG_BRIDGE_ADDR
                   if (incr) addr <= addr + step;
`endif
`ifdef NOC_BUG_BRESP_PERBEAT
                   st <= B_WRESP;                       // BUG: a B for every beat
`else
                   st <= wlast_l ? B_WRESP : B_WBEAT;
`endif
                 end
      B_WRESP: if (m_bready[sel]) begin
`ifdef NOC_BUG_BRESP_PERBEAT
                 st <= wlast_l ? B_IDLE : B_WBEAT;
`else
                 st <= B_IDLE;
`endif
               end

      // ---- read: run an APB read transfer, drive a beat ----
      B_RSETUP: st <= B_RACCESS;
      B_RACCESS: if (p_pready) begin
                   rd_l   <= p_prdata;
`ifdef NOC_BUG_PSLVERR_SWALLOW
                   rerr_l <= 1'b0;
`else
                   rerr_l <= p_pslverr;
`endif
                   st <= B_RBEAT;
                 end
      B_RBEAT: if (m_rready[sel]) begin
`ifndef NOC_BUG_BRIDGE_ADDR
                 if (incr) addr <= addr + step;
`endif
                 if (rbeat == 8'd0) st <= B_IDLE;
                 else begin rbeat <= rbeat - 8'd1; st <= B_RSETUP; end
               end

      default: st <= B_IDLE;
    endcase
  end

endmodule : axi2apb_bridge
