// ============================================================================
//  axi_slave_bfm.sv  —  simple behavioral AXI slave (smoke test only)
// ----------------------------------------------------------------------------
//  Memory-backed, always-ready, single-outstanding per direction (matches what
//  the Phase-1 NoC issues to a slave).  Connects via the axi_if.slave modport
//  so no signal-by-signal port list is needed.  NOT used by the UVM env.
// ============================================================================
`timescale 1ns/1ps
module axi_slave_bfm import noc_pkg::*; #(parameter int RD_LAT = 0) (axi_if.slave s);

  byte unsigned mem [int];   // byte-addressed backing memory

  // ----------------------------- Write -----------------------------
  typedef enum logic [1:0] {WR_AW, WR_W, WR_B} wr_e;
  wr_e                     wr;
  logic [SLV_ID_WIDTH-1:0] w_id;
  logic [ADDR_WIDTH-1:0]   w_addr;
  logic [2:0]              w_size;
  logic [1:0]              w_burst;

  assign s.awready = (wr == WR_AW);
  assign s.wready  = (wr == WR_W);
  assign s.bid     = w_id;
  assign s.bresp   = AXI_RESP_OKAY;
  assign s.bvalid  = (wr == WR_B);

  always_ff @(posedge s.aclk or negedge s.aresetn) begin
    if (!s.aresetn) begin
      wr <= WR_AW;
    end else case (wr)
      WR_AW: if (s.awvalid) begin
               w_id<=s.awid; w_addr<=s.awaddr; w_size<=s.awsize; w_burst<=s.awburst; wr<=WR_W;
             end
      WR_W:  if (s.wvalid) begin
               for (int b=0;b<STRB_WIDTH;b++) if (s.wstrb[b]) mem[w_addr+b]=s.wdata[8*b +: 8];
               if (w_burst==AXI_BURST_INCR) w_addr<=w_addr+(1<<w_size);
               if (s.wlast) wr<=WR_B;
             end
      WR_B:  if (s.bready) wr<=WR_AW;
      default: wr<=WR_AW;
    endcase
  end

  // ----------------------------- Read ------------------------------
  typedef enum logic [1:0] {RD_AR, RD_WAIT, RD_R} rd_e;
  rd_e                     rd;
  logic [SLV_ID_WIDTH-1:0] r_id;
  logic [ADDR_WIDTH-1:0]   r_addr;
  logic [2:0]              r_size;
  logic [1:0]              r_burst;
  logic [7:0]              r_beat;
  int                      r_wait;

  logic [DATA_WIDTH-1:0] rdat;
  always_comb begin
    rdat = '0;
    for (int b=0;b<STRB_WIDTH;b++) rdat[8*b +: 8] = mem.exists(r_addr+b) ? mem[r_addr+b] : 8'h0;
  end

  assign s.arready = (rd == RD_AR);
  assign s.rid     = r_id;
  assign s.rdata   = rdat;
  assign s.rresp   = AXI_RESP_OKAY;
  assign s.rlast   = (rd == RD_R) && (r_beat == 8'd0);
  assign s.rvalid  = (rd == RD_R);

  always_ff @(posedge s.aclk or negedge s.aresetn) begin
    if (!s.aresetn) begin
      rd <= RD_AR;
    end else case (rd)
      RD_AR: if (s.arvalid) begin
               r_id<=s.arid; r_addr<=s.araddr; r_size<=s.arsize; r_burst<=s.arburst; r_beat<=s.arlen;
               r_wait<=RD_LAT; rd<=(RD_LAT==0)?RD_R:RD_WAIT;
             end
      RD_WAIT: if (r_wait<=1) rd<=RD_R; else r_wait<=r_wait-1;
      RD_R:  if (s.rready) begin
               if (r_beat == 8'd0) rd <= RD_AR;
               else begin
                 r_beat <= r_beat - 8'd1;
                 if (r_burst==AXI_BURST_INCR) r_addr <= r_addr + (1<<r_size);
               end
             end
      default: rd <= RD_AR;
    endcase
  end

endmodule : axi_slave_bfm
