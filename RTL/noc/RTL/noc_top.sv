// ============================================================================
//  noc_top.sv  —  2x2x2 Network-on-Chip  (DUT top, flattened AXI/APB ports)
// ----------------------------------------------------------------------------
//  Masters (NoC is AXI slave):  m0_*, m1_*        ID width = ID_WIDTH (4)
//  AXI slaves (NoC is master):  s0_*, s1_*        ID width = SLV_ID_WIDTH (5)
//  APB slaves (NoC is requester): p0_*, p1_*
//
//  Self-contained RTL: depends only on noc_pkg, never on the testbench.
//
//  NOTE: Phase-0 skeleton.  The body ties all outputs to a safe idle so the
//  design elaborates; the real fabric is wired in Phase 1 (noc_fabric).
// ============================================================================
module noc_top
  import noc_pkg::*;
(
  input  logic                    aclk,
  input  logic                    aresetn,

  // ===================== Master 0  (AXI slave port) =======================
  input  logic [ID_WIDTH-1:0]     m0_awid,
  input  logic [ADDR_WIDTH-1:0]   m0_awaddr,
  input  logic [7:0]              m0_awlen,
  input  logic [2:0]              m0_awsize,
  input  logic [1:0]              m0_awburst,
  input  logic                    m0_awlock,
  input  logic [3:0]              m0_awcache,
  input  logic [2:0]              m0_awprot,
  input  logic [3:0]              m0_awqos,
  input  logic                    m0_awvalid,
  output logic                    m0_awready,
  input  logic [DATA_WIDTH-1:0]   m0_wdata,
  input  logic [STRB_WIDTH-1:0]   m0_wstrb,
  input  logic                    m0_wlast,
  input  logic                    m0_wvalid,
  output logic                    m0_wready,
  output logic [ID_WIDTH-1:0]     m0_bid,
  output logic [1:0]              m0_bresp,
  output logic                    m0_bvalid,
  input  logic                    m0_bready,
  input  logic [ID_WIDTH-1:0]     m0_arid,
  input  logic [ADDR_WIDTH-1:0]   m0_araddr,
  input  logic [7:0]              m0_arlen,
  input  logic [2:0]              m0_arsize,
  input  logic [1:0]              m0_arburst,
  input  logic                    m0_arlock,
  input  logic [3:0]              m0_arcache,
  input  logic [2:0]              m0_arprot,
  input  logic [3:0]              m0_arqos,
  input  logic                    m0_arvalid,
  output logic                    m0_arready,
  output logic [ID_WIDTH-1:0]     m0_rid,
  output logic [DATA_WIDTH-1:0]   m0_rdata,
  output logic [1:0]              m0_rresp,
  output logic                    m0_rlast,
  output logic                    m0_rvalid,
  input  logic                    m0_rready,

  // ===================== Master 1  (AXI slave port) =======================
  input  logic [ID_WIDTH-1:0]     m1_awid,
  input  logic [ADDR_WIDTH-1:0]   m1_awaddr,
  input  logic [7:0]              m1_awlen,
  input  logic [2:0]              m1_awsize,
  input  logic [1:0]              m1_awburst,
  input  logic                    m1_awlock,
  input  logic [3:0]              m1_awcache,
  input  logic [2:0]              m1_awprot,
  input  logic [3:0]              m1_awqos,
  input  logic                    m1_awvalid,
  output logic                    m1_awready,
  input  logic [DATA_WIDTH-1:0]   m1_wdata,
  input  logic [STRB_WIDTH-1:0]   m1_wstrb,
  input  logic                    m1_wlast,
  input  logic                    m1_wvalid,
  output logic                    m1_wready,
  output logic [ID_WIDTH-1:0]     m1_bid,
  output logic [1:0]              m1_bresp,
  output logic                    m1_bvalid,
  input  logic                    m1_bready,
  input  logic [ID_WIDTH-1:0]     m1_arid,
  input  logic [ADDR_WIDTH-1:0]   m1_araddr,
  input  logic [7:0]              m1_arlen,
  input  logic [2:0]              m1_arsize,
  input  logic [1:0]              m1_arburst,
  input  logic                    m1_arlock,
  input  logic [3:0]              m1_arcache,
  input  logic [2:0]              m1_arprot,
  input  logic [3:0]              m1_arqos,
  input  logic                    m1_arvalid,
  output logic                    m1_arready,
  output logic [ID_WIDTH-1:0]     m1_rid,
  output logic [DATA_WIDTH-1:0]   m1_rdata,
  output logic [1:0]              m1_rresp,
  output logic                    m1_rlast,
  output logic                    m1_rvalid,
  input  logic                    m1_rready,

  // ===================== AXI Slave 0  (AXI master port) ===================
  output logic [SLV_ID_WIDTH-1:0] s0_awid,
  output logic [ADDR_WIDTH-1:0]   s0_awaddr,
  output logic [7:0]              s0_awlen,
  output logic [2:0]              s0_awsize,
  output logic [1:0]              s0_awburst,
  output logic                    s0_awlock,
  output logic [3:0]              s0_awcache,
  output logic [2:0]              s0_awprot,
  output logic [3:0]              s0_awqos,
  output logic                    s0_awvalid,
  input  logic                    s0_awready,
  output logic [DATA_WIDTH-1:0]   s0_wdata,
  output logic [STRB_WIDTH-1:0]   s0_wstrb,
  output logic                    s0_wlast,
  output logic                    s0_wvalid,
  input  logic                    s0_wready,
  input  logic [SLV_ID_WIDTH-1:0] s0_bid,
  input  logic [1:0]              s0_bresp,
  input  logic                    s0_bvalid,
  output logic                    s0_bready,
  output logic [SLV_ID_WIDTH-1:0] s0_arid,
  output logic [ADDR_WIDTH-1:0]   s0_araddr,
  output logic [7:0]              s0_arlen,
  output logic [2:0]              s0_arsize,
  output logic [1:0]              s0_arburst,
  output logic                    s0_arlock,
  output logic [3:0]              s0_arcache,
  output logic [2:0]              s0_arprot,
  output logic [3:0]              s0_arqos,
  output logic                    s0_arvalid,
  input  logic                    s0_arready,
  input  logic [SLV_ID_WIDTH-1:0] s0_rid,
  input  logic [DATA_WIDTH-1:0]   s0_rdata,
  input  logic [1:0]              s0_rresp,
  input  logic                    s0_rlast,
  input  logic                    s0_rvalid,
  output logic                    s0_rready,

  // ===================== AXI Slave 1  (AXI master port) ===================
  output logic [SLV_ID_WIDTH-1:0] s1_awid,
  output logic [ADDR_WIDTH-1:0]   s1_awaddr,
  output logic [7:0]              s1_awlen,
  output logic [2:0]              s1_awsize,
  output logic [1:0]              s1_awburst,
  output logic                    s1_awlock,
  output logic [3:0]              s1_awcache,
  output logic [2:0]              s1_awprot,
  output logic [3:0]              s1_awqos,
  output logic                    s1_awvalid,
  input  logic                    s1_awready,
  output logic [DATA_WIDTH-1:0]   s1_wdata,
  output logic [STRB_WIDTH-1:0]   s1_wstrb,
  output logic                    s1_wlast,
  output logic                    s1_wvalid,
  input  logic                    s1_wready,
  input  logic [SLV_ID_WIDTH-1:0] s1_bid,
  input  logic [1:0]              s1_bresp,
  input  logic                    s1_bvalid,
  output logic                    s1_bready,
  output logic [SLV_ID_WIDTH-1:0] s1_arid,
  output logic [ADDR_WIDTH-1:0]   s1_araddr,
  output logic [7:0]              s1_arlen,
  output logic [2:0]              s1_arsize,
  output logic [1:0]              s1_arburst,
  output logic                    s1_arlock,
  output logic [3:0]              s1_arcache,
  output logic [2:0]              s1_arprot,
  output logic [3:0]              s1_arqos,
  output logic                    s1_arvalid,
  input  logic                    s1_arready,
  input  logic [SLV_ID_WIDTH-1:0] s1_rid,
  input  logic [DATA_WIDTH-1:0]   s1_rdata,
  input  logic [1:0]              s1_rresp,
  input  logic                    s1_rlast,
  input  logic                    s1_rvalid,
  output logic                    s1_rready,

  // ===================== APB Slave 0  (APB requester port) ================
  output logic [ADDR_WIDTH-1:0]   p0_paddr,
  output logic [2:0]              p0_pprot,
  output logic                    p0_psel,
  output logic                    p0_penable,
  output logic                    p0_pwrite,
  output logic [DATA_WIDTH-1:0]   p0_pwdata,
  output logic [STRB_WIDTH-1:0]   p0_pstrb,
  input  logic [DATA_WIDTH-1:0]   p0_prdata,
  input  logic                    p0_pready,
  input  logic                    p0_pslverr,

  // ===================== APB Slave 1  (APB requester port) ================
  output logic [ADDR_WIDTH-1:0]   p1_paddr,
  output logic [2:0]              p1_pprot,
  output logic                    p1_psel,
  output logic                    p1_penable,
  output logic                    p1_pwrite,
  output logic [DATA_WIDTH-1:0]   p1_pwdata,
  output logic [STRB_WIDTH-1:0]   p1_pstrb,
  input  logic [DATA_WIDTH-1:0]   p1_prdata,
  input  logic                    p1_pready,
  input  logic                    p1_pslverr
);

  // ==========================================================================
  //  Fabric (Phase 1): decode -> route to one of five target servers
  //  (S0, S1, P0-bridge, P1-bridge, DECERR) -> mux responses back.
  //  Single outstanding per master per direction (wbusy/rbusy), extended to
  //  full multi-outstanding / OOO in Phase 2.
  // ==========================================================================

  // ---- Master-side request signals packed into per-master arrays ----
  logic [ID_WIDTH-1:0]   mst_awid    [NUM_MASTERS];
  logic [ADDR_WIDTH-1:0] mst_awaddr  [NUM_MASTERS];
  logic [7:0]            mst_awlen   [NUM_MASTERS];
  logic [2:0]            mst_awsize  [NUM_MASTERS];
  logic [1:0]            mst_awburst [NUM_MASTERS];
  logic [2:0]            mst_awprot  [NUM_MASTERS];
  logic [3:0]            mst_awqos   [NUM_MASTERS];
  logic [DATA_WIDTH-1:0] mst_wdata   [NUM_MASTERS];
  logic [STRB_WIDTH-1:0] mst_wstrb   [NUM_MASTERS];
  logic                  mst_wlast   [NUM_MASTERS];
  logic                  mst_wvalid  [NUM_MASTERS];
  logic                  mst_bready  [NUM_MASTERS];
  logic [ID_WIDTH-1:0]   mst_arid    [NUM_MASTERS];
  logic [ADDR_WIDTH-1:0] mst_araddr  [NUM_MASTERS];
  logic [7:0]            mst_arlen   [NUM_MASTERS];
  logic [2:0]            mst_arsize  [NUM_MASTERS];
  logic [1:0]            mst_arburst [NUM_MASTERS];
  logic [2:0]            mst_arprot  [NUM_MASTERS];
  logic [3:0]            mst_arqos   [NUM_MASTERS];
  logic                  mst_rready  [NUM_MASTERS];

  assign mst_awid[0]=m0_awid; assign mst_awaddr[0]=m0_awaddr; assign mst_awlen[0]=m0_awlen;
  assign mst_awsize[0]=m0_awsize; assign mst_awburst[0]=m0_awburst; assign mst_awprot[0]=m0_awprot;
  assign mst_awqos[0]=m0_awqos;
  assign mst_wdata[0]=m0_wdata; assign mst_wstrb[0]=m0_wstrb; assign mst_wlast[0]=m0_wlast; assign mst_wvalid[0]=m0_wvalid;
  assign mst_bready[0]=m0_bready;
  assign mst_arid[0]=m0_arid; assign mst_araddr[0]=m0_araddr; assign mst_arlen[0]=m0_arlen;
  assign mst_arsize[0]=m0_arsize; assign mst_arburst[0]=m0_arburst; assign mst_arprot[0]=m0_arprot;
  assign mst_arqos[0]=m0_arqos; assign mst_rready[0]=m0_rready;

  assign mst_awid[1]=m1_awid; assign mst_awaddr[1]=m1_awaddr; assign mst_awlen[1]=m1_awlen;
  assign mst_awsize[1]=m1_awsize; assign mst_awburst[1]=m1_awburst; assign mst_awprot[1]=m1_awprot;
  assign mst_awqos[1]=m1_awqos;
  assign mst_wdata[1]=m1_wdata; assign mst_wstrb[1]=m1_wstrb; assign mst_wlast[1]=m1_wlast; assign mst_wvalid[1]=m1_wvalid;
  assign mst_bready[1]=m1_bready;
  assign mst_arid[1]=m1_arid; assign mst_araddr[1]=m1_araddr; assign mst_arlen[1]=m1_arlen;
  assign mst_arsize[1]=m1_arsize; assign mst_arburst[1]=m1_arburst; assign mst_arprot[1]=m1_arprot;
  assign mst_arqos[1]=m1_arqos; assign mst_rready[1]=m1_rready;

  // ---- Address decode per master (AW and AR) ----
  target_e dec_aw [NUM_MASTERS];
  target_e dec_ar [NUM_MASTERS];
  assign dec_aw[0] = decode(m0_awaddr);  assign dec_aw[1] = decode(m1_awaddr);
  assign dec_ar[0] = decode(m0_araddr);  assign dec_ar[1] = decode(m1_araddr);

  // ---- Single-outstanding WRITE busy flags (writes are 1-outstanding/master) ----
  logic wbusy [NUM_MASTERS];

  // ---- Per-master READ outstanding tracker (multi-outstanding, OOO) ----
  //  out_cnt[i][id] : reads of this id in flight for master i
  //  out_tgt[i][id] : target those in-flight same-id reads went to
  //  rtotal[i]      : total reads in flight for master i (capped)
  localparam int unsigned NUM_ID = (1 << ID_WIDTH);
  logic [3:0]   out_cnt [NUM_MASTERS][NUM_ID];
  target_e      out_tgt [NUM_MASTERS][NUM_ID];
  logic [4:0]   rtotal  [NUM_MASTERS];
  logic [ID_WIDTH-1:0] arid_i [NUM_MASTERS];
  logic         ar_allow [NUM_MASTERS];
  assign arid_i[0] = m0_arid;  assign arid_i[1] = m1_arid;
  for (genvar i = 0; i < NUM_MASTERS; i++) begin : g_arallow
    // cap not reached AND not a same-id read aimed at a different target
    assign ar_allow[i] = (rtotal[i] < MAX_OUTSTANDING)
`ifndef NOC_BUG_SAMEID_REORDER
                       & ~((out_cnt[i][arid_i[i]] != 0) & (out_tgt[i][arid_i[i]] != dec_ar[i]))
`endif
                       ;
  end

  // ---- Per-server gated request valids (only the decoded server sees it) ----
  logic awv_s0[NUM_MASTERS], awv_s1[NUM_MASTERS], awv_p0[NUM_MASTERS], awv_p1[NUM_MASTERS], awv_dc[NUM_MASTERS];
  logic arv_s0[NUM_MASTERS], arv_s1[NUM_MASTERS], arv_p0[NUM_MASTERS], arv_p1[NUM_MASTERS], arv_dc[NUM_MASTERS];
  for (genvar i = 0; i < NUM_MASTERS; i++) begin : g_gate
    assign awv_s0[i] = (i==0?m0_awvalid:m1_awvalid) & (dec_aw[i]==TGT_S0)   & ~wbusy[i];
    assign awv_s1[i] = (i==0?m0_awvalid:m1_awvalid) & (dec_aw[i]==TGT_S1)   & ~wbusy[i];
    assign awv_p0[i] = (i==0?m0_awvalid:m1_awvalid) & (dec_aw[i]==TGT_P0)   & ~wbusy[i];
    assign awv_p1[i] = (i==0?m0_awvalid:m1_awvalid) & (dec_aw[i]==TGT_P1)   & ~wbusy[i];
    assign awv_dc[i] = (i==0?m0_awvalid:m1_awvalid) & (dec_aw[i]==TGT_NONE) & ~wbusy[i];
    assign arv_s0[i] = (i==0?m0_arvalid:m1_arvalid) & (dec_ar[i]==TGT_S0)   & ar_allow[i];
    assign arv_s1[i] = (i==0?m0_arvalid:m1_arvalid) & (dec_ar[i]==TGT_S1)   & ar_allow[i];
    assign arv_p0[i] = (i==0?m0_arvalid:m1_arvalid) & (dec_ar[i]==TGT_P0)   & ar_allow[i];
    assign arv_p1[i] = (i==0?m0_arvalid:m1_arvalid) & (dec_ar[i]==TGT_P1)   & ar_allow[i];
    assign arv_dc[i] = (i==0?m0_arvalid:m1_arvalid) & (dec_ar[i]==TGT_NONE) & ar_allow[i];
  end

  // ---- Per-server response signals (one set per target server) ----
  logic s0_awr[NUM_MASTERS], s0_wr[NUM_MASTERS], s0_bv[NUM_MASTERS], s0_arr[NUM_MASTERS], s0_rv[NUM_MASTERS], s0_rl[NUM_MASTERS];
  logic s1_awr[NUM_MASTERS], s1_wr[NUM_MASTERS], s1_bv[NUM_MASTERS], s1_arr[NUM_MASTERS], s1_rv[NUM_MASTERS], s1_rl[NUM_MASTERS];
  logic p0_awr[NUM_MASTERS], p0_wr[NUM_MASTERS], p0_bv[NUM_MASTERS], p0_arr[NUM_MASTERS], p0_rv[NUM_MASTERS], p0_rl[NUM_MASTERS];
  logic p1_awr[NUM_MASTERS], p1_wr[NUM_MASTERS], p1_bv[NUM_MASTERS], p1_arr[NUM_MASTERS], p1_rv[NUM_MASTERS], p1_rl[NUM_MASTERS];
  logic dc_awr[NUM_MASTERS], dc_wr[NUM_MASTERS], dc_bv[NUM_MASTERS], dc_arr[NUM_MASTERS], dc_rv[NUM_MASTERS], dc_rl[NUM_MASTERS];
  logic [ID_WIDTH-1:0]   s0_mbid[NUM_MASTERS], s0_mrid[NUM_MASTERS], s1_mbid[NUM_MASTERS], s1_mrid[NUM_MASTERS],
                         p0_bid[NUM_MASTERS], p0_rid[NUM_MASTERS], p1_bid[NUM_MASTERS], p1_rid[NUM_MASTERS],
                         dc_bid[NUM_MASTERS], dc_rid[NUM_MASTERS];
  logic [1:0]            s0_br[NUM_MASTERS], s0_rr[NUM_MASTERS], s1_br[NUM_MASTERS], s1_rr[NUM_MASTERS],
                         p0_br[NUM_MASTERS], p0_rr[NUM_MASTERS], p1_br[NUM_MASTERS], p1_rr[NUM_MASTERS],
                         dc_br[NUM_MASTERS], dc_rr[NUM_MASTERS];
  logic [DATA_WIDTH-1:0] s0_rd[NUM_MASTERS], s1_rd[NUM_MASTERS], p0_rd[NUM_MASTERS], p1_rd[NUM_MASTERS], dc_rd[NUM_MASTERS];

  // ---- Per-server gated RREADY (driven by the per-master R-burst-lock mux) ----
  logic rrdy_s0[NUM_MASTERS], rrdy_s1[NUM_MASTERS], rrdy_p0[NUM_MASTERS], rrdy_p1[NUM_MASTERS], rrdy_dc[NUM_MASTERS];
  // ---- Per-master read-burst lock select: 0=s0 1=s1 2=p0 3=p1 4=dc ----
  logic [2:0] rsel  [NUM_MASTERS];
  logic       rany  [NUM_MASTERS];
  logic       rlock [NUM_MASTERS];
  logic [2:0] rlsel [NUM_MASTERS];

  // ---- AXI slave servers (S0, S1) ----
  noc_axi_slave_port u_s0 (
    .aclk, .aresetn,
    .m_awid(mst_awid), .m_awaddr(mst_awaddr), .m_awlen(mst_awlen), .m_awsize(mst_awsize),
    .m_awburst(mst_awburst), .m_awprot(mst_awprot), .m_awqos(mst_awqos),
    .m_awvalid(awv_s0), .m_awready(s0_awr),
    .m_wdata(mst_wdata), .m_wstrb(mst_wstrb), .m_wlast(mst_wlast), .m_wvalid(mst_wvalid), .m_wready(s0_wr),
    .m_bid(s0_mbid), .m_bresp(s0_br), .m_bvalid(s0_bv), .m_bready(mst_bready),
    .m_arid(mst_arid), .m_araddr(mst_araddr), .m_arlen(mst_arlen), .m_arsize(mst_arsize),
    .m_arburst(mst_arburst), .m_arprot(mst_arprot), .m_arqos(mst_arqos),
    .m_arvalid(arv_s0), .m_arready(s0_arr),
    .m_rid(s0_mrid), .m_rdata(s0_rd), .m_rresp(s0_rr), .m_rlast(s0_rl), .m_rvalid(s0_rv), .m_rready(rrdy_s0),
    .s_awid(s0_awid), .s_awaddr(s0_awaddr), .s_awlen(s0_awlen), .s_awsize(s0_awsize), .s_awburst(s0_awburst),
    .s_awlock(s0_awlock), .s_awcache(s0_awcache), .s_awprot(s0_awprot), .s_awqos(s0_awqos),
    .s_awvalid(s0_awvalid), .s_awready(s0_awready),
    .s_wdata(s0_wdata), .s_wstrb(s0_wstrb), .s_wlast(s0_wlast), .s_wvalid(s0_wvalid), .s_wready(s0_wready),
    .s_bid(s0_bid), .s_bresp(s0_bresp), .s_bvalid(s0_bvalid), .s_bready(s0_bready),
    .s_arid(s0_arid), .s_araddr(s0_araddr), .s_arlen(s0_arlen), .s_arsize(s0_arsize), .s_arburst(s0_arburst),
    .s_arlock(s0_arlock), .s_arcache(s0_arcache), .s_arprot(s0_arprot), .s_arqos(s0_arqos),
    .s_arvalid(s0_arvalid), .s_arready(s0_arready),
    .s_rid(s0_rid), .s_rdata(s0_rdata), .s_rresp(s0_rresp), .s_rlast(s0_rlast), .s_rvalid(s0_rvalid), .s_rready(s0_rready)
  );

  noc_axi_slave_port u_s1 (
    .aclk, .aresetn,
    .m_awid(mst_awid), .m_awaddr(mst_awaddr), .m_awlen(mst_awlen), .m_awsize(mst_awsize),
    .m_awburst(mst_awburst), .m_awprot(mst_awprot), .m_awqos(mst_awqos),
    .m_awvalid(awv_s1), .m_awready(s1_awr),
    .m_wdata(mst_wdata), .m_wstrb(mst_wstrb), .m_wlast(mst_wlast), .m_wvalid(mst_wvalid), .m_wready(s1_wr),
    .m_bid(s1_mbid), .m_bresp(s1_br), .m_bvalid(s1_bv), .m_bready(mst_bready),
    .m_arid(mst_arid), .m_araddr(mst_araddr), .m_arlen(mst_arlen), .m_arsize(mst_arsize),
    .m_arburst(mst_arburst), .m_arprot(mst_arprot), .m_arqos(mst_arqos),
    .m_arvalid(arv_s1), .m_arready(s1_arr),
    .m_rid(s1_mrid), .m_rdata(s1_rd), .m_rresp(s1_rr), .m_rlast(s1_rl), .m_rvalid(s1_rv), .m_rready(rrdy_s1),
    .s_awid(s1_awid), .s_awaddr(s1_awaddr), .s_awlen(s1_awlen), .s_awsize(s1_awsize), .s_awburst(s1_awburst),
    .s_awlock(s1_awlock), .s_awcache(s1_awcache), .s_awprot(s1_awprot), .s_awqos(s1_awqos),
    .s_awvalid(s1_awvalid), .s_awready(s1_awready),
    .s_wdata(s1_wdata), .s_wstrb(s1_wstrb), .s_wlast(s1_wlast), .s_wvalid(s1_wvalid), .s_wready(s1_wready),
    .s_bid(s1_bid), .s_bresp(s1_bresp), .s_bvalid(s1_bvalid), .s_bready(s1_bready),
    .s_arid(s1_arid), .s_araddr(s1_araddr), .s_arlen(s1_arlen), .s_arsize(s1_arsize), .s_arburst(s1_arburst),
    .s_arlock(s1_arlock), .s_arcache(s1_arcache), .s_arprot(s1_arprot), .s_arqos(s1_arqos),
    .s_arvalid(s1_arvalid), .s_arready(s1_arready),
    .s_rid(s1_rid), .s_rdata(s1_rdata), .s_rresp(s1_rresp), .s_rlast(s1_rlast), .s_rvalid(s1_rvalid), .s_rready(s1_rready)
  );

  // ---- AXI->APB bridges (P0, P1) ----
  axi2apb_bridge u_p0 (
    .aclk, .aresetn,
    .m_awid(mst_awid), .m_awaddr(mst_awaddr), .m_awlen(mst_awlen), .m_awsize(mst_awsize),
    .m_awburst(mst_awburst), .m_awprot(mst_awprot), .m_awqos(mst_awqos),
    .m_awvalid(awv_p0), .m_awready(p0_awr),
    .m_wdata(mst_wdata), .m_wstrb(mst_wstrb), .m_wlast(mst_wlast), .m_wvalid(mst_wvalid), .m_wready(p0_wr),
    .m_bid(p0_bid), .m_bresp(p0_br), .m_bvalid(p0_bv), .m_bready(mst_bready),
    .m_arid(mst_arid), .m_araddr(mst_araddr), .m_arlen(mst_arlen), .m_arsize(mst_arsize),
    .m_arburst(mst_arburst), .m_arprot(mst_arprot), .m_arqos(mst_arqos),
    .m_arvalid(arv_p0), .m_arready(p0_arr),
    .m_rid(p0_rid), .m_rdata(p0_rd), .m_rresp(p0_rr), .m_rlast(p0_rl), .m_rvalid(p0_rv), .m_rready(rrdy_p0),
    .p_paddr(p0_paddr), .p_pprot(p0_pprot), .p_psel(p0_psel), .p_penable(p0_penable),
    .p_pwrite(p0_pwrite), .p_pwdata(p0_pwdata), .p_pstrb(p0_pstrb),
    .p_prdata(p0_prdata), .p_pready(p0_pready), .p_pslverr(p0_pslverr)
  );

  axi2apb_bridge u_p1 (
    .aclk, .aresetn,
    .m_awid(mst_awid), .m_awaddr(mst_awaddr), .m_awlen(mst_awlen), .m_awsize(mst_awsize),
    .m_awburst(mst_awburst), .m_awprot(mst_awprot), .m_awqos(mst_awqos),
    .m_awvalid(awv_p1), .m_awready(p1_awr),
    .m_wdata(mst_wdata), .m_wstrb(mst_wstrb), .m_wlast(mst_wlast), .m_wvalid(mst_wvalid), .m_wready(p1_wr),
    .m_bid(p1_bid), .m_bresp(p1_br), .m_bvalid(p1_bv), .m_bready(mst_bready),
    .m_arid(mst_arid), .m_araddr(mst_araddr), .m_arlen(mst_arlen), .m_arsize(mst_arsize),
    .m_arburst(mst_arburst), .m_arprot(mst_arprot), .m_arqos(mst_arqos),
    .m_arvalid(arv_p1), .m_arready(p1_arr),
    .m_rid(p1_rid), .m_rdata(p1_rd), .m_rresp(p1_rr), .m_rlast(p1_rl), .m_rvalid(p1_rv), .m_rready(rrdy_p1),
    .p_paddr(p1_paddr), .p_pprot(p1_pprot), .p_psel(p1_psel), .p_penable(p1_penable),
    .p_pwrite(p1_pwrite), .p_pwdata(p1_pwdata), .p_pstrb(p1_pstrb),
    .p_prdata(p1_prdata), .p_pready(p1_pready), .p_pslverr(p1_pslverr)
  );

  // ---- DECERR responder (unmapped) ----
  noc_decerr_port u_dc (
    .aclk, .aresetn,
    .m_awid(mst_awid), .m_awlen(mst_awlen), .m_awqos(mst_awqos), .m_awvalid(awv_dc), .m_awready(dc_awr),
    .m_wlast(mst_wlast), .m_wvalid(mst_wvalid), .m_wready(dc_wr),
    .m_bid(dc_bid), .m_bresp(dc_br), .m_bvalid(dc_bv), .m_bready(mst_bready),
    .m_arid(mst_arid), .m_arlen(mst_arlen), .m_arqos(mst_arqos), .m_arvalid(arv_dc), .m_arready(dc_arr),
    .m_rid(dc_rid), .m_rdata(dc_rd), .m_rresp(dc_rr), .m_rlast(dc_rl), .m_rvalid(dc_rv), .m_rready(rrdy_dc)
  );

  // ---- Response mux back to each master (only one server is active per dir) ----
  assign m0_awready = s0_awr[0] | s1_awr[0] | p0_awr[0] | p1_awr[0] | dc_awr[0];
  assign m0_wready  = s0_wr[0]  | s1_wr[0]  | p0_wr[0]  | p1_wr[0]  | dc_wr[0];
  assign m0_bvalid  = s0_bv[0]  | s1_bv[0]  | p0_bv[0]  | p1_bv[0]  | dc_bv[0];
  assign m0_bid     = s0_bv[0]?s0_mbid[0] : s1_bv[0]?s1_mbid[0] : p0_bv[0]?p0_bid[0] : p1_bv[0]?p1_bid[0] : dc_bid[0];
  assign m0_bresp   = s0_bv[0]?s0_br[0]  : s1_bv[0]?s1_br[0]  : p0_bv[0]?p0_br[0]  : p1_bv[0]?p1_br[0]  : dc_br[0];
  assign m0_arready = s0_arr[0] | s1_arr[0] | p0_arr[0] | p1_arr[0] | dc_arr[0];
  assign m1_awready = s0_awr[1] | s1_awr[1] | p0_awr[1] | p1_awr[1] | dc_awr[1];
  assign m1_wready  = s0_wr[1]  | s1_wr[1]  | p0_wr[1]  | p1_wr[1]  | dc_wr[1];
  assign m1_bvalid  = s0_bv[1]  | s1_bv[1]  | p0_bv[1]  | p1_bv[1]  | dc_bv[1];
  assign m1_bid     = s0_bv[1]?s0_mbid[1] : s1_bv[1]?s1_mbid[1] : p0_bv[1]?p0_bid[1] : p1_bv[1]?p1_bid[1] : dc_bid[1];
  assign m1_bresp   = s0_bv[1]?s0_br[1]  : s1_bv[1]?s1_br[1]  : p0_bv[1]?p0_br[1]  : p1_bv[1]?p1_br[1]  : dc_br[1];
  assign m1_arready = s0_arr[1] | s1_arr[1] | p0_arr[1] | p1_arr[1] | dc_arr[1];

  // ---- Read response: per-master burst-lock mux across the five servers ----
  logic                  mrvalid [NUM_MASTERS];
  logic [ID_WIDTH-1:0]   mrid    [NUM_MASTERS];
  logic [DATA_WIDTH-1:0] mrdata  [NUM_MASTERS];
  logic [1:0]            mrresp  [NUM_MASTERS];
  logic                  mrlast  [NUM_MASTERS];

  always_comb begin
    for (int i = 0; i < NUM_MASTERS; i++) begin
      logic                  rvv [5];
      logic [ID_WIDTH-1:0]   rids[5];
      logic [DATA_WIDTH-1:0] rds [5];
      logic [1:0]            rrs [5];
      logic                  rls [5];
      logic [2:0]            s;
      logic                  found;
      logic                  mr;
      rvv[0]=s0_rv[i]; rvv[1]=s1_rv[i]; rvv[2]=p0_rv[i]; rvv[3]=p1_rv[i]; rvv[4]=dc_rv[i];
      rids[0]=s0_mrid[i]; rids[1]=s1_mrid[i]; rids[2]=p0_rid[i]; rids[3]=p1_rid[i]; rids[4]=dc_rid[i];
      rds[0]=s0_rd[i]; rds[1]=s1_rd[i]; rds[2]=p0_rd[i]; rds[3]=p1_rd[i]; rds[4]=dc_rd[i];
      rrs[0]=s0_rr[i]; rrs[1]=s1_rr[i]; rrs[2]=p0_rr[i]; rrs[3]=p1_rr[i]; rrs[4]=dc_rr[i];
      rls[0]=s0_rl[i]; rls[1]=s1_rl[i]; rls[2]=p0_rl[i]; rls[3]=p1_rl[i]; rls[4]=dc_rl[i];

      if (rlock[i]) s = rlsel[i];
      else begin
        s = 3'd0; found = 1'b0;
        for (int k = 0; k < 5; k++) if (!found && rvv[k]) begin s = k[2:0]; found = 1'b1; end
      end
      rsel[i] = s;
      rany[i] = rvv[s];

      mrvalid[i] = rany[i];
      mrid[i]    = rids[s];
      mrdata[i]  = rds[s];
      mrresp[i]  = rrs[s];
      mrlast[i]  = rls[s];

      // per-server gated rready: only the selected server for this master
      mr = (i == 0) ? m0_rready : m1_rready;
      rrdy_s0[i] = mr & rany[i] & (s == 3'd0);
      rrdy_s1[i] = mr & rany[i] & (s == 3'd1);
      rrdy_p0[i] = mr & rany[i] & (s == 3'd2);
      rrdy_p1[i] = mr & rany[i] & (s == 3'd3);
      rrdy_dc[i] = mr & rany[i] & (s == 3'd4);
    end
  end

  assign m0_rvalid = mrvalid[0]; assign m0_rid = mrid[0]; assign m0_rdata = mrdata[0];
  assign m0_rresp  = mrresp[0];  assign m0_rlast = mrlast[0];
  assign m1_rvalid = mrvalid[1]; assign m1_rid = mrid[1]; assign m1_rdata = mrdata[1];
  assign m1_rresp  = mrresp[1];  assign m1_rlast = mrlast[1];

  // ---- Write single-outstanding busy tracking ----
  always_ff @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
      wbusy[0] <= 1'b0; wbusy[1] <= 1'b0;
    end else begin
      if      (m0_awvalid && m0_awready) wbusy[0] <= 1'b1;
      else if (m0_bvalid  && m0_bready)  wbusy[0] <= 1'b0;
      if      (m1_awvalid && m1_awready) wbusy[1] <= 1'b1;
      else if (m1_bvalid  && m1_bready)  wbusy[1] <= 1'b0;
    end
  end

  // ---- Read burst lock + outstanding tracker ----
  logic        ar_acc [NUM_MASTERS];
  logic        r_done [NUM_MASTERS];
  logic        arv_i  [NUM_MASTERS];
  logic        arr_i  [NUM_MASTERS];
  assign arv_i[0]=m0_arvalid; assign arv_i[1]=m1_arvalid;
  assign arr_i[0]=m0_arready; assign arr_i[1]=m1_arready;
  for (genvar i = 0; i < NUM_MASTERS; i++) begin : g_acc
    assign ar_acc[i] = arv_i[i] & arr_i[i];
    assign r_done[i] = mrvalid[i] & ((i==0)?m0_rready:m1_rready) & mrlast[i];
  end

  always_ff @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
      for (int i = 0; i < NUM_MASTERS; i++) begin
        rlock[i] <= 1'b0; rlsel[i] <= 3'd0; rtotal[i] <= '0;
        for (int k = 0; k < NUM_ID; k++) begin out_cnt[i][k] <= '0; out_tgt[i][k] <= TGT_S0; end
      end
    end else begin
      for (int i = 0; i < NUM_MASTERS; i++) begin
        // burst lock: hold the selected server until rlast
        if (mrvalid[i] && ((i==0)?m0_rready:m1_rready)) begin
          if (mrlast[i]) rlock[i] <= 1'b0;
          else begin     rlock[i] <= 1'b1; rlsel[i] <= rsel[i]; end
        end
        // outstanding counters
        rtotal[i] <= rtotal[i] + (ar_acc[i] ? 5'd1 : 5'd0) - (r_done[i] ? 5'd1 : 5'd0);
        for (int k = 0; k < NUM_ID; k++) begin
          logic inc, dec;
          inc = ar_acc[i] && (arid_i[i] == k[ID_WIDTH-1:0]);
          dec = r_done[i] && (mrid[i]   == k[ID_WIDTH-1:0]);
          out_cnt[i][k] <= out_cnt[i][k] + (inc ? 4'd1 : 4'd0) - (dec ? 4'd1 : 4'd0);
          if (inc) out_tgt[i][k] <= dec_ar[i];
        end
      end
    end
  end

endmodule : noc_top
