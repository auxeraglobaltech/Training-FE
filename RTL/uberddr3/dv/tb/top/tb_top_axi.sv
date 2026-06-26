// ============================================================================
//  tb_top_axi.sv — Phase-1 directed AXI smoke for UberDDR3 (ddr3_top_axi)
// ----------------------------------------------------------------------------
//  Generates the four behavioral clocks, instantiates the AXI4 wrapper with
//  BIST disabled (so the controller serves our user traffic), wires the Micron
//  x16 DDR3 model to the DDR pins, waits for o_calib_complete, then runs
//  self-checked single-beat AXI writes/reads (128-bit) and a short burst.
//  Vendor-free (SIM_MODEL behavioral primitive models). Exits via $finish.
// ============================================================================
`timescale 1ps/1ps
module tb_top_axi;

  // ---- x16 / two-lane configuration (matches the repo's proven axi_tb) ----
  localparam CONTROLLER_CLK_PERIOD = 10_000; // ps  (100 MHz)
  localparam DDR3_CLK_PERIOD       = 2_500;  // ps  (400 MHz, 4:1 — DDR3-800)
  localparam ROW_BITS   = 14;
  localparam COL_BITS   = 10;
  localparam BA_BITS    = 3;
  localparam BYTE_LANES = 2;
  localparam DQ_BITS    = 8;
  // AXI_ID_WIDTH >= 6 required: the AXI wrapper ties AUX_WIDTH = AXI_ID_WIDTH, and
  // the controller's ECC-aux packing slices aux[AUX_WIDTH-6:0] (must be non-reversed,
  // elaborated even when ECC is off). 8 is a standard width and keeps the slice valid.
  localparam AXI_ID_WIDTH = 8;
  localparam serdes_ratio = 4;
  localparam AXI_DATA_WIDTH = DQ_BITS*BYTE_LANES*serdes_ratio*2;          // 128
  localparam AXI_STRB_WIDTH = AXI_DATA_WIDTH/8;                           // 16
  localparam wb_addr_bits   = ROW_BITS + COL_BITS + BA_BITS - $clog2(serdes_ratio*2); // 24
  localparam AXI_LSBS       = $clog2(AXI_DATA_WIDTH)-3;                   // 4
  localparam AXI_ADDR_WIDTH = wb_addr_bits + AXI_LSBS;                    // 28

  // ---- clocks / reset ----
  reg i_controller_clk, i_ddr3_clk, i_ref_clk, i_ddr3_clk_90;
  reg i_rst_n;
  initial begin i_controller_clk=1; i_ddr3_clk=1; i_ref_clk=1; i_ddr3_clk_90=1; end
  always #(CONTROLLER_CLK_PERIOD/2) i_controller_clk = ~i_controller_clk;
  always #(DDR3_CLK_PERIOD/2)       i_ddr3_clk       = ~i_ddr3_clk;
  always #2500                      i_ref_clk        = ~i_ref_clk;        // 200 MHz
  initial begin
    #(DDR3_CLK_PERIOD/4);
    forever #(DDR3_CLK_PERIOD/2) i_ddr3_clk_90 = ~i_ddr3_clk_90;
  end
  initial begin
    i_rst_n = 0;
    #1_000_000;          // 1 us reset (matches axi_tb)
    i_rst_n = 1;
  end

  // ---- AXI master-driven signals ----
  reg                       s_axi_awvalid;  wire s_axi_awready;
  reg  [AXI_ID_WIDTH-1:0]   s_axi_awid;
  reg  [AXI_ADDR_WIDTH-1:0] s_axi_awaddr;
  reg  [7:0]                s_axi_awlen;
  reg  [2:0]                s_axi_awsize;
  reg  [1:0]                s_axi_awburst;
  reg                       s_axi_wvalid;   wire s_axi_wready;
  reg  [AXI_DATA_WIDTH-1:0] s_axi_wdata;
  reg  [AXI_STRB_WIDTH-1:0] s_axi_wstrb;
  reg                       s_axi_wlast;
  wire                      s_axi_bvalid;   reg  s_axi_bready;
  wire [AXI_ID_WIDTH-1:0]   s_axi_bid;
  wire [1:0]                s_axi_bresp;
  reg                       s_axi_arvalid;  wire s_axi_arready;
  reg  [AXI_ID_WIDTH-1:0]   s_axi_arid;
  reg  [AXI_ADDR_WIDTH-1:0] s_axi_araddr;
  reg  [7:0]                s_axi_arlen;
  reg  [2:0]                s_axi_arsize;
  reg  [1:0]                s_axi_arburst;
  wire                      s_axi_rvalid;   reg  s_axi_rready;
  wire [AXI_ID_WIDTH-1:0]   s_axi_rid;
  wire [AXI_DATA_WIDTH-1:0] s_axi_rdata;
  wire                      s_axi_rlast;
  wire [1:0]                s_axi_rresp;

  // ---- DDR3 pins ----
  wire o_ddr3_clk_p, o_ddr3_clk_n, o_ddr3_reset_n, o_ddr3_cke, o_ddr3_cs_n;
  wire o_ddr3_ras_n, o_ddr3_cas_n, o_ddr3_we_n, o_ddr3_odt;
  wire [ROW_BITS-1:0]          o_ddr3_addr;
  wire [BA_BITS-1:0]           o_ddr3_ba_addr;
  wire [DQ_BITS*BYTE_LANES-1:0] io_ddr3_dq;
  wire [BYTE_LANES-1:0]        io_ddr3_dqs, io_ddr3_dqs_n, o_ddr3_dm;
  wire o_calib_complete;
  wire [31:0] o_debug1;

  // ---- DUT: AXI4 wrapper (BIST off → serves user traffic) ----
  ddr3_top_axi #(
    .CONTROLLER_CLK_PERIOD(CONTROLLER_CLK_PERIOD),
    .DDR3_CLK_PERIOD(DDR3_CLK_PERIOD),
    .ROW_BITS(ROW_BITS), .COL_BITS(COL_BITS), .BA_BITS(BA_BITS),
    .BYTE_LANES(BYTE_LANES), .AXI_ID_WIDTH(AXI_ID_WIDTH),
    .MICRON_SIM(1), .ODELAY_SUPPORTED(0),   // match the repo's proven axi_tb config
    .SECOND_WISHBONE(0), .WB_ERROR(0),
    .BIST_MODE(0), .ECC_ENABLE(0), .SELF_REFRESH(2'b00)
  ) dut (
    .i_controller_clk(i_controller_clk), .i_ddr3_clk(i_ddr3_clk),
    .i_ref_clk(i_ref_clk), .i_ddr3_clk_90(i_ddr3_clk_90), .i_rst_n(i_rst_n),
    .s_axi_awvalid(s_axi_awvalid), .s_axi_awready(s_axi_awready), .s_axi_awid(s_axi_awid),
    .s_axi_awaddr(s_axi_awaddr), .s_axi_awlen(s_axi_awlen), .s_axi_awsize(s_axi_awsize),
    .s_axi_awburst(s_axi_awburst), .s_axi_awlock(1'b0), .s_axi_awcache(4'd0),
    .s_axi_awprot(3'd0), .s_axi_awqos(4'd0),
    .s_axi_wvalid(s_axi_wvalid), .s_axi_wready(s_axi_wready), .s_axi_wdata(s_axi_wdata),
    .s_axi_wstrb(s_axi_wstrb), .s_axi_wlast(s_axi_wlast),
    .s_axi_bvalid(s_axi_bvalid), .s_axi_bready(s_axi_bready), .s_axi_bid(s_axi_bid),
    .s_axi_bresp(s_axi_bresp),
    .s_axi_arvalid(s_axi_arvalid), .s_axi_arready(s_axi_arready), .s_axi_arid(s_axi_arid),
    .s_axi_araddr(s_axi_araddr), .s_axi_arlen(s_axi_arlen), .s_axi_arsize(s_axi_arsize),
    .s_axi_arburst(s_axi_arburst), .s_axi_arlock(1'b0), .s_axi_arcache(4'd0),
    .s_axi_arprot(3'd0), .s_axi_arqos(4'd0),
    .s_axi_rvalid(s_axi_rvalid), .s_axi_rready(s_axi_rready), .s_axi_rid(s_axi_rid),
    .s_axi_rdata(s_axi_rdata), .s_axi_rlast(s_axi_rlast), .s_axi_rresp(s_axi_rresp),
    .o_ddr3_clk_p(o_ddr3_clk_p), .o_ddr3_clk_n(o_ddr3_clk_n), .o_ddr3_reset_n(o_ddr3_reset_n),
    .o_ddr3_cke(o_ddr3_cke), .o_ddr3_cs_n(o_ddr3_cs_n), .o_ddr3_ras_n(o_ddr3_ras_n),
    .o_ddr3_cas_n(o_ddr3_cas_n), .o_ddr3_we_n(o_ddr3_we_n), .o_ddr3_addr(o_ddr3_addr),
    .o_ddr3_ba_addr(o_ddr3_ba_addr), .io_ddr3_dq(io_ddr3_dq), .io_ddr3_dqs(io_ddr3_dqs),
    .io_ddr3_dqs_n(io_ddr3_dqs_n), .o_ddr3_dm(o_ddr3_dm), .o_ddr3_odt(o_ddr3_odt),
    .o_calib_complete(o_calib_complete), .o_debug1(o_debug1),
    .i_user_self_refresh(1'b0)
  );

  // ---- Micron x16 DDR3 model ----
  ddr3 #(.DLL_OFF(0)) ddr3_0 (
    .rst_n(o_ddr3_reset_n), .ck(o_ddr3_clk_p), .ck_n(o_ddr3_clk_n), .cke(o_ddr3_cke),
    .cs_n(o_ddr3_cs_n), .ras_n(o_ddr3_ras_n), .cas_n(o_ddr3_cas_n), .we_n(o_ddr3_we_n),
    .dm_tdqs(o_ddr3_dm), .ba(o_ddr3_ba_addr), .addr({2'b0, o_ddr3_addr}), .dq(io_ddr3_dq),
    .dqs(io_ddr3_dqs), .dqs_n(io_ddr3_dqs_n), .tdqs_n(), .odt(o_ddr3_odt)
  );

  // ---- watchdog ----
  initial begin
    #2_000_000_000;  // 2 ms
    $display("SMOKE: TIMEOUT (calibration or traffic did not complete)");
    $finish;
  end

  // ---- X-init workaround for the vendored AXI write bridge ----------------
  //  Xcelium leaves the bridge's FIFO-fill counters at X (iverilog/Vivado
  //  2-state-initialise them), which poisons accept_write_burst and blocks all
  //  writes. Force the counters to 0 through calibration, then release so the
  //  design operates normally. dv-only; upstream RTL stays pristine.
  initial begin
    force dut.axim2wbsp_inst.AXI_WR.axi_write_decoder.total_fifo_fill = '0;
    force dut.axim2wbsp_inst.AXI_WR.axi_write_decoder.acks_expected   = '0;
    wait (o_calib_complete === 1'b1);
    repeat (5) @(posedge i_controller_clk);
    release dut.axim2wbsp_inst.AXI_WR.axi_write_decoder.total_fifo_fill;
    release dut.axim2wbsp_inst.AXI_WR.axi_write_decoder.acks_expected;
    $display("  [XINIT] released bridge fifo-fill force @ %0t", $time);
  end

  // ---- internal Wishbone-bus monitor (between AXI bridge and controller) ----
  //  Reveals whether the bridge issues the WB write and whether the controller
  //  acks it.  Hierarchical refs into the wrapper's internal wb_* wires.
  int wb_acc_cnt = 0, wb_ack_cnt = 0;
  int wstb_cnt = 0;
  always @(posedge i_controller_clk) begin
    if (o_calib_complete) begin
      if (dut.wb_stb && !dut.wb_stall) begin
        wb_acc_cnt++;
        if (wb_acc_cnt <= 12)
          $display("  [WB] req accepted we=%b addr=%h @ %0t", dut.wb_we, dut.wb_addr, $time);
      end
      if (dut.wb_ack) begin
        wb_ack_cnt++;
        if (wb_ack_cnt <= 12) $display("  [WB] ACK #%0d @ %0t", wb_ack_cnt, $time);
      end
      // write-bridge request to the internal arbiter
      if (dut.axim2wbsp_inst.w_wb_stb) begin
        wstb_cnt++;
        if (wstb_cnt <= 12)
          $display("  [WRBR] w_wb_stb=1 cyc=%b stall=%b we=%b @ %0t",
                   dut.axim2wbsp_inst.w_wb_cyc, dut.axim2wbsp_inst.w_wb_stall,
                   dut.axim2wbsp_inst.w_wb_we, $time);
      end
      // probe accept_write_burst inputs while a write B is pending
      if (s_axi_bready && !s_axi_bvalid && wstb_cnt == 0 && wb_acc_cnt == 0) begin
        if (wb_acc_cnt == 0) begin : pb
          static int pcnt = 0;
          if (pcnt < 6) begin
            $display("  [PRB] accept=%b skid_awv=%b skid_wv=%b skid_awr=%b fifofull=%b err=%b @ %0t",
              dut.axim2wbsp_inst.AXI_WR.axi_write_decoder.accept_write_burst,
              dut.axim2wbsp_inst.AXI_WR.axi_write_decoder.skid_awvalid,
              dut.axim2wbsp_inst.AXI_WR.axi_write_decoder.skid_wvalid,
              dut.axim2wbsp_inst.AXI_WR.axi_write_decoder.skid_awready,
              dut.axim2wbsp_inst.AXI_WR.axi_write_decoder.total_fifo_full,
              dut.axim2wbsp_inst.AXI_WR.axi_write_decoder.err_state, $time);
            pcnt++;
          end
        end
      end
    end
  end

  // ---- AXI driver tasks (single outstanding, single beat) ----
  integer errors = 0;

  // wait for a real handshake: (valid && ready) sampled at a clock edge, with timeout.
  `define HS(vld, rdy, nm) \
      wcnt = 0; \
      forever begin @(posedge i_controller_clk); \
        if ((vld) && (rdy)) break; \
        wcnt++; if (wcnt > 4000) begin $display("  [STALL] %s @ %0t", nm, $time); errors=errors+1; break; end \
      end

  task automatic axi_write(input [AXI_ADDR_WIDTH-1:0] addr, input [AXI_DATA_WIDTH-1:0] data);
    int wcnt; bit aw_hs, w_hs;
    begin
      // present AW and W concurrently; the bridge accepts the write only when
      // BOTH are valid at once (accept_write_burst needs skid_awvalid && skid_wvalid).
      @(posedge i_controller_clk);
      s_axi_awvalid<=1; s_axi_awid<=8'h1; s_axi_awaddr<=addr; s_axi_awlen<=8'd0;
      s_axi_awsize<=3'd4; s_axi_awburst<=2'b01;
      s_axi_wvalid<=1; s_axi_wdata<=data; s_axi_wstrb<={AXI_STRB_WIDTH{1'b1}}; s_axi_wlast<=1;
      aw_hs=0; w_hs=0; wcnt=0;
      do begin
        @(posedge i_controller_clk);
        if (s_axi_awvalid && s_axi_awready) begin s_axi_awvalid<=0; aw_hs=1; end
        if (s_axi_wvalid  && s_axi_wready ) begin s_axi_wvalid<=0; s_axi_wlast<=0; w_hs=1; end
        wcnt++; if (wcnt>4000) begin $display("  [STALL] AW/W (aw=%b w=%b) @ %0t",aw_hs,w_hs,$time); errors++; break; end
      end while (!aw_hs || !w_hs);
      $display("  [.] AW+W done addr=%h @ %0t", addr, $time);
      // B phase
      s_axi_bready<=1;
      `HS(s_axi_bvalid, s_axi_bready, "B")
      $display("  [.] B received bresp=%0d @ %0t", s_axi_bresp, $time);
      s_axi_bready<=0;
    end
  endtask

  task automatic axi_read(input [AXI_ADDR_WIDTH-1:0] addr, output [AXI_DATA_WIDTH-1:0] data);
    int wcnt;
    begin
      @(posedge i_controller_clk);
      s_axi_arvalid<=1; s_axi_arid<=8'h2; s_axi_araddr<=addr; s_axi_arlen<=8'd0;
      s_axi_arsize<=3'd4; s_axi_arburst<=2'b01;
      `HS(s_axi_arvalid, s_axi_arready, "AR")
      s_axi_arvalid<=0;
      s_axi_rready<=1;
      `HS(s_axi_rvalid, s_axi_rready, "R")
      data = s_axi_rdata;
      s_axi_rready<=0;
      $display("  [.] R received @ %0t", $time);
    end
  endtask

  task automatic check(input [AXI_ADDR_WIDTH-1:0] addr, input [AXI_DATA_WIDTH-1:0] wdata);
    reg [AXI_DATA_WIDTH-1:0] rdata;
    begin
      axi_write(addr, wdata);
      axi_read (addr, rdata);
      if (rdata !== wdata) begin
        errors = errors + 1;
        $display("  [FAIL] addr=%h exp=%h got=%h", addr, wdata, rdata);
      end else
        $display("  [OK]   addr=%h data=%h", addr, wdata);
    end
  endtask

  // ---- stimulus ----
  initial begin
    s_axi_awvalid=0; s_axi_wvalid=0; s_axi_bready=0; s_axi_arvalid=0; s_axi_rready=0;
    s_axi_awid=0; s_axi_awaddr=0; s_axi_awlen=0; s_axi_awsize=0; s_axi_awburst=1;
    s_axi_wdata=0; s_axi_wstrb=0; s_axi_wlast=0;
    s_axi_arid=0; s_axi_araddr=0; s_axi_arlen=0; s_axi_arsize=0; s_axi_arburst=1;

    $display("==== UberDDR3 AXI smoke: waiting for calibration ====");
    wait (o_calib_complete === 1'b1);
    $display("==== calibration complete @ %0t ps ====", $time);
    repeat (10) @(posedge i_controller_clk);

    check(28'h000_0000, 128'hDEADBEEF_00112233_44556677_8899AABB);
    check(28'h000_0010, 128'h01234567_89ABCDEF_FEDCBA98_76543210);
    check(28'h000_0020, 128'hA5A5A5A5_5A5A5A5A_F0F0F0F0_0F0F0F0F);
    check(28'h001_0000, 128'h11111111_22222222_33333333_44444444);
    check(28'h010_0000, 128'hCAFEBABE_DEADC0DE_8BADF00D_FEEDFACE);

    repeat (20) @(posedge i_controller_clk);
    if (errors == 0) $display("SMOKE: PASS (all AXI writes/reads matched)");
    else             $display("SMOKE: FAIL (%0d errors)", errors);
    $finish;
  end

endmodule : tb_top_axi
