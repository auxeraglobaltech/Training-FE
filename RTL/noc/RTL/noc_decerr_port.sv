// ============================================================================
//  noc_decerr_port.sv  —  DECERR responder for unmapped addresses
// ----------------------------------------------------------------------------
//  Behaves like a target server but has no slave behind it: it accepts the
//  request (consuming all write beats), then returns a clean DECERR so the
//  master always recovers and the fabric never hangs.
//    write: swallow W beats -> single B = DECERR
//    read : AR -> (arlen+1) R beats, each RDATA=0 / RRESP=DECERR, RLAST on last
//
//  Bug hook NOC_BUG_DECERR_OMIT: never returns a response (fabric hangs;
//  the tb_top watchdog turns the hang into a UVM_ERROR).
// ============================================================================
module noc_decerr_port
  import noc_pkg::*;
(
  input  logic                  aclk,
  input  logic                  aresetn,

  // ---- master-facing (valids pre-gated to "decoded NONE" by the fabric) ----
  input  logic [ID_WIDTH-1:0]   m_awid    [NUM_MASTERS],
  input  logic [7:0]            m_awlen   [NUM_MASTERS],
  input  logic [3:0]            m_awqos   [NUM_MASTERS],
  input  logic                  m_awvalid [NUM_MASTERS],
  output logic                  m_awready [NUM_MASTERS],
  input  logic                  m_wlast   [NUM_MASTERS],
  input  logic                  m_wvalid  [NUM_MASTERS],
  output logic                  m_wready  [NUM_MASTERS],
  output logic [ID_WIDTH-1:0]   m_bid     [NUM_MASTERS],
  output logic [1:0]            m_bresp   [NUM_MASTERS],
  output logic                  m_bvalid  [NUM_MASTERS],
  input  logic                  m_bready  [NUM_MASTERS],

  input  logic [ID_WIDTH-1:0]   m_arid    [NUM_MASTERS],
  input  logic [7:0]            m_arlen   [NUM_MASTERS],
  input  logic [3:0]            m_arqos   [NUM_MASTERS],
  input  logic                  m_arvalid [NUM_MASTERS],
  output logic                  m_arready [NUM_MASTERS],
  output logic [ID_WIDTH-1:0]   m_rid     [NUM_MASTERS],
  output logic [DATA_WIDTH-1:0] m_rdata   [NUM_MASTERS],
  output logic [1:0]            m_rresp   [NUM_MASTERS],
  output logic                  m_rlast   [NUM_MASTERS],
  output logic                  m_rvalid  [NUM_MASTERS],
  input  logic                  m_rready  [NUM_MASTERS]
);

  // -------------------------------------------------------------------------
  //  Write side
  // -------------------------------------------------------------------------
  typedef enum logic [1:0] {DW_IDLE, DW_DATA, DW_RESP} dw_e;
  dw_e                 dw_state;
  logic                dw_sel;
  logic [ID_WIDTH-1:0] dw_id;

  logic dw_req0, dw_req1, dw_g0, dw_g1, dw_gv, dw_gidx, dw_upd;
  assign dw_req0 = m_awvalid[0];
  assign dw_req1 = m_awvalid[1];
  noc_arbiter u_dwarb (.clk(aclk), .rstn(aresetn), .req0(dw_req0), .req1(dw_req1),
                       .prio0(m_awqos[0]), .prio1(m_awqos[1]), .update(dw_upd),
                       .gnt0(dw_g0), .gnt1(dw_g1), .gnt_valid(dw_gv), .gnt_idx(dw_gidx));

  always_comb begin
    for (int i = 0; i < NUM_MASTERS; i++) begin
      m_awready[i] = 1'b0; m_wready[i] = 1'b0;
      m_bvalid[i]  = 1'b0; m_bid[i] = dw_id; m_bresp[i] = AXI_RESP_DECERR;
    end
    dw_upd = 1'b0;
    unique case (dw_state)
      DW_IDLE: begin
        // accept the AW immediately for the granted master
        if (dw_gv) begin
          m_awready[dw_gidx] = 1'b1;
          dw_upd             = 1'b1;
        end
      end
      DW_DATA: begin
        m_wready[dw_sel] = 1'b1;          // swallow write beats
      end
      DW_RESP: begin
`ifndef NOC_BUG_DECERR_OMIT
        m_bvalid[dw_sel] = 1'b1;
        m_bid[dw_sel]    = dw_id;
        m_bresp[dw_sel]  = AXI_RESP_DECERR;
`endif
      end
      default: ;
    endcase
  end

  always_ff @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
      dw_state <= DW_IDLE; dw_sel <= 1'b0; dw_id <= '0;
    end else case (dw_state)
      DW_IDLE: if (dw_gv) begin
                 dw_sel <= dw_gidx; dw_id <= m_awid[dw_gidx]; dw_state <= DW_DATA;
               end
      DW_DATA: if (m_wvalid[dw_sel] && m_wlast[dw_sel]) dw_state <= DW_RESP;
      DW_RESP: if (m_bvalid[dw_sel] && m_bready[dw_sel]) dw_state <= DW_IDLE;
      default: dw_state <= DW_IDLE;
    endcase
  end

  // -------------------------------------------------------------------------
  //  Read side
  // -------------------------------------------------------------------------
  typedef enum logic [0:0] {DR_IDLE, DR_DATA} dr_e;
  dr_e                 dr_state;
  logic                dr_sel;
  logic [ID_WIDTH-1:0] dr_id;
  logic [7:0]          dr_beat;     // beats remaining-1 .. 0
  logic [7:0]          dr_len;

  logic dr_req0, dr_req1, dr_g0, dr_g1, dr_gv, dr_gidx, dr_upd;
  assign dr_req0 = m_arvalid[0];
  assign dr_req1 = m_arvalid[1];
  noc_arbiter u_drarb (.clk(aclk), .rstn(aresetn), .req0(dr_req0), .req1(dr_req1),
                       .prio0(m_arqos[0]), .prio1(m_arqos[1]), .update(dr_upd),
                       .gnt0(dr_g0), .gnt1(dr_g1), .gnt_valid(dr_gv), .gnt_idx(dr_gidx));

  always_comb begin
    for (int i = 0; i < NUM_MASTERS; i++) begin
      m_arready[i] = 1'b0;
      m_rvalid[i]  = 1'b0; m_rid[i] = dr_id; m_rdata[i] = '0;
      m_rresp[i]   = AXI_RESP_DECERR; m_rlast[i] = 1'b0;
    end
    dr_upd = 1'b0;
    unique case (dr_state)
      DR_IDLE: begin
        if (dr_gv) begin
          m_arready[dr_gidx] = 1'b1;
          dr_upd             = 1'b1;
        end
      end
      DR_DATA: begin
`ifndef NOC_BUG_DECERR_OMIT
        m_rvalid[dr_sel] = 1'b1;
        m_rid[dr_sel]    = dr_id;
        m_rdata[dr_sel]  = '0;
        m_rresp[dr_sel]  = AXI_RESP_DECERR;
        m_rlast[dr_sel]  = (dr_beat == 8'd0);
`endif
      end
      default: ;
    endcase
  end

  always_ff @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
      dr_state <= DR_IDLE; dr_sel <= 1'b0; dr_id <= '0; dr_beat <= '0; dr_len <= '0;
    end else case (dr_state)
      DR_IDLE: if (dr_gv) begin
                 dr_sel  <= dr_gidx; dr_id <= m_arid[dr_gidx];
                 dr_len  <= m_arlen[dr_gidx]; dr_beat <= m_arlen[dr_gidx];
                 dr_state<= DR_DATA;
               end
      DR_DATA: if (m_rvalid[dr_sel] && m_rready[dr_sel]) begin
                 if (dr_beat == 8'd0) dr_state <= DR_IDLE;
                 else                 dr_beat  <= dr_beat - 8'd1;
               end
      default: dr_state <= DR_IDLE;
    endcase
  end

endmodule : noc_decerr_port
