// ============================================================================
//  noc_axi_slave_port.sv  —  write + read server for one AXI slave (S0/S1)
// ----------------------------------------------------------------------------
//  Arbitrates the two masters for this slave and forwards one transaction at a
//  time (Phase 1: single outstanding per direction).  The slave-facing ID is
//  remapped to {master_index, original_id} (SLV_ID_WIDTH) so out-of-order slave
//  responses route back unambiguously; the original ID is returned to the
//  master on B/R.
//
//  Write FSM:  W_IDLE (arbitrate + drive AW) -> W_DATA (stream W) -> W_RESP (B)
//  Read  FSM:  R_IDLE (arbitrate + drive AR) -> R_DATA (stream R)
// ============================================================================
module noc_axi_slave_port
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

  // ---- slave-facing AXI master port (remapped ID) ----
  output logic [SLV_ID_WIDTH-1:0] s_awid,
  output logic [ADDR_WIDTH-1:0]   s_awaddr,
  output logic [7:0]              s_awlen,
  output logic [2:0]              s_awsize,
  output logic [1:0]              s_awburst,
  output logic                    s_awlock,
  output logic [3:0]              s_awcache,
  output logic [2:0]              s_awprot,
  output logic [3:0]              s_awqos,
  output logic                    s_awvalid,
  input  logic                    s_awready,
  output logic [DATA_WIDTH-1:0]   s_wdata,
  output logic [STRB_WIDTH-1:0]   s_wstrb,
  output logic                    s_wlast,
  output logic                    s_wvalid,
  input  logic                    s_wready,
  input  logic [SLV_ID_WIDTH-1:0] s_bid,
  input  logic [1:0]              s_bresp,
  input  logic                    s_bvalid,
  output logic                    s_bready,
  output logic [SLV_ID_WIDTH-1:0] s_arid,
  output logic [ADDR_WIDTH-1:0]   s_araddr,
  output logic [7:0]              s_arlen,
  output logic [2:0]              s_arsize,
  output logic [1:0]              s_arburst,
  output logic                    s_arlock,
  output logic [3:0]              s_arcache,
  output logic [2:0]              s_arprot,
  output logic [3:0]              s_arqos,
  output logic                    s_arvalid,
  input  logic                    s_arready,
  input  logic [SLV_ID_WIDTH-1:0] s_rid,
  input  logic [DATA_WIDTH-1:0]   s_rdata,
  input  logic [1:0]              s_rresp,
  input  logic                    s_rlast,
  input  logic                    s_rvalid,
  output logic                    s_rready
);

  // =========================================================================
  //  Write path
  // =========================================================================
  typedef enum logic [1:0] {W_IDLE, W_DATA, W_RESP} w_e;
  w_e                  wstate;
  logic                w_sel;
  logic [ID_WIDTH-1:0] w_id;

  logic w_g0, w_g1, w_gv, w_gidx, w_upd;
  noc_arbiter u_warb (.clk(aclk), .rstn(aresetn),
                      .req0(m_awvalid[0]), .req1(m_awvalid[1]),
                      .prio0(m_awqos[0]), .prio1(m_awqos[1]), .update(w_upd),
                      .gnt0(w_g0), .gnt1(w_g1), .gnt_valid(w_gv), .gnt_idx(w_gidx));

  always_comb begin
    for (int i = 0; i < NUM_MASTERS; i++) begin
      m_awready[i] = 1'b0; m_wready[i] = 1'b0;
      m_bvalid[i]  = 1'b0; m_bid[i] = w_id; m_bresp[i] = '0;
    end
    s_awvalid = 1'b0; s_awid = '0; s_awaddr = '0; s_awlen = '0; s_awsize = '0;
    s_awburst = '0; s_awlock = 1'b0; s_awcache = 4'b0011; s_awprot = '0; s_awqos = '0;
    s_wvalid = 1'b0; s_wdata = '0; s_wstrb = '0; s_wlast = 1'b0;
    s_bready = 1'b0;
    w_upd = 1'b0;

    unique case (wstate)
      W_IDLE: if (w_gv) begin
        s_awvalid          = 1'b1;
        s_awid             = {w_gidx, m_awid[w_gidx]};
        s_awaddr           = m_awaddr[w_gidx];
        s_awlen            = m_awlen[w_gidx];
        s_awsize           = m_awsize[w_gidx];
        s_awburst          = m_awburst[w_gidx];
        s_awprot           = m_awprot[w_gidx];
        s_awqos            = m_awqos[w_gidx];
        m_awready[w_gidx]  = s_awready;
        w_upd              = s_awready;
      end
      W_DATA: begin
        s_wvalid        = m_wvalid[w_sel];
        s_wdata         = m_wdata[w_sel];
        s_wstrb         = m_wstrb[w_sel];
        s_wlast         = m_wlast[w_sel];
        m_wready[w_sel] = s_wready;
      end
      W_RESP: begin
        m_bvalid[w_sel] = s_bvalid;
        m_bid[w_sel]    = w_id;
        m_bresp[w_sel]  = s_bresp;
        s_bready        = m_bready[w_sel];
      end
      default: ;
    endcase
  end

  always_ff @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
      wstate <= W_IDLE; w_sel <= 1'b0; w_id <= '0;
    end else case (wstate)
      W_IDLE: if (w_gv && s_awready) begin
                w_sel <= w_gidx; w_id <= m_awid[w_gidx]; wstate <= W_DATA;
              end
      W_DATA: if (s_wvalid && s_wready && s_wlast) wstate <= W_RESP;
      W_RESP: if (s_bvalid && s_bready)            wstate <= W_IDLE;
      default: wstate <= W_IDLE;
    endcase
  end

  // =========================================================================
  //  Read path  (multi-outstanding passthrough)
  // ----------------------------------------------------------------------------
  //  AR is arbitrated and forwarded to the slave back-to-back (no wait for R),
  //  so many reads can be in flight.  The slave returns R bursts tagged with the
  //  remapped id {master_index, orig_id}; we demux each R beat back to its master
  //  purely by the id's top bit.  The slave guarantees per-id ordering and
  //  contiguous bursts, so at any beat exactly one master is addressed.
  //  Outstanding-count and same-id ordering are enforced upstream (noc_top).
  // =========================================================================
  logic r_g0, r_g1, r_gv, r_gidx, r_upd;
  noc_arbiter u_rarb (.clk(aclk), .rstn(aresetn),
                      .req0(m_arvalid[0]), .req1(m_arvalid[1]),
                      .prio0(m_arqos[0]), .prio1(m_arqos[1]), .update(r_upd),
                      .gnt0(r_g0), .gnt1(r_g1), .gnt_valid(r_gv), .gnt_idx(r_gidx));

  // Which master this R beat belongs to (top bit of the remapped slave id)
  logic r_dst;
  assign r_dst = s_rid[SLV_ID_WIDTH-1];

  always_comb begin
    for (int i = 0; i < NUM_MASTERS; i++) begin
      m_arready[i] = 1'b0;
      m_rvalid[i]  = 1'b0; m_rid[i] = '0; m_rdata[i] = '0; m_rresp[i] = '0; m_rlast[i] = 1'b0;
    end

    // ---- AR forward (combinational, accepted when slave is ready) ----
    s_arvalid = r_gv;
    s_arid    = r_gv ? {r_gidx, m_arid[r_gidx]} : '0;
    s_araddr  = m_araddr[r_gidx];
    s_arlen   = m_arlen[r_gidx];
    s_arsize  = m_arsize[r_gidx];
    s_arburst = m_arburst[r_gidx];
    s_arlock  = 1'b0; s_arcache = 4'b0011; s_arprot = m_arprot[r_gidx]; s_arqos = m_arqos[r_gidx];
    if (r_gv) m_arready[r_gidx] = s_arready;
    r_upd = r_gv & s_arready;          // rotate RR pointer on each accepted AR

    // ---- R demux back to the owning master by id top bit ----
    m_rvalid[r_dst] = s_rvalid;
    m_rid[r_dst]    = s_rid[ID_WIDTH-1:0];
    m_rdata[r_dst]  = s_rdata;
    m_rresp[r_dst]  = s_rresp;
    m_rlast[r_dst]  = s_rlast;
    s_rready        = m_rready[r_dst];
  end

endmodule : noc_axi_slave_port
