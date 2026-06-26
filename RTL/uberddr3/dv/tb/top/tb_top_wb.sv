// ============================================================================
//  tb_top_wb.sv — directed Wishbone smoke for UberDDR3 (ddr3_top, native WB)
// ----------------------------------------------------------------------------
//  Drives the controller's native pipelined Wishbone interface (the proven
//  user interface; Phase-0 BIST passed on it). Generates the four behavioral
//  clocks, instantiates ddr3_top with BIST off, wires the Micron x16 model,
//  waits for o_calib_complete, then runs self-checked single-outstanding
//  word writes/reads (128-bit). Vendor-free (SIM_MODEL). Exits via $finish.
// ============================================================================
`timescale 1ps/1ps
module tb_top_wb;

  localparam CONTROLLER_CLK_PERIOD = 10_000; // ps
  localparam DDR3_CLK_PERIOD       = 2_500;  // ps (4:1)
  localparam ROW_BITS   = 14, COL_BITS = 10, BA_BITS = 3, BYTE_LANES = 2, DQ_BITS = 8;
  localparam AUX_WIDTH  = 16;                // >=6 (ECC-aux slice); matches Phase-0
  localparam serdes_ratio = 4;
  localparam WB_DATA_BITS = DQ_BITS*BYTE_LANES*serdes_ratio*2;            // 128
  localparam WB_SEL_BITS  = WB_DATA_BITS/8;                               // 16
  localparam WB_ADDR_BITS = ROW_BITS+COL_BITS+BA_BITS-$clog2(serdes_ratio*2); // 24

  // ---- clocks / reset ----
  reg i_controller_clk, i_ddr3_clk, i_ref_clk, i_ddr3_clk_90, i_rst_n;
  initial begin i_controller_clk=1; i_ddr3_clk=1; i_ref_clk=1; i_ddr3_clk_90=1; end
  always #(CONTROLLER_CLK_PERIOD/2) i_controller_clk = ~i_controller_clk;
  always #(DDR3_CLK_PERIOD/2)       i_ddr3_clk       = ~i_ddr3_clk;
  always #2500                      i_ref_clk        = ~i_ref_clk;
  initial begin #(DDR3_CLK_PERIOD/4); forever #(DDR3_CLK_PERIOD/2) i_ddr3_clk_90 = ~i_ddr3_clk_90; end
  initial begin i_rst_n=0; #1_000_000; i_rst_n=1; end

  // ---- Wishbone (master-driven) ----
  reg                      i_wb_cyc, i_wb_stb, i_wb_we;
  reg  [WB_ADDR_BITS-1:0]  i_wb_addr;
  reg  [WB_DATA_BITS-1:0]  i_wb_data;
  reg  [WB_SEL_BITS-1:0]   i_wb_sel;
  reg  [AUX_WIDTH-1:0]     i_aux;
  wire                     o_wb_stall, o_wb_ack, o_wb_err;
  wire [WB_DATA_BITS-1:0]  o_wb_data;
  wire [AUX_WIDTH-1:0]     o_aux;

  // ---- DDR3 pins (single rank) ----
  wire o_ddr3_clk_p, o_ddr3_clk_n, o_ddr3_reset_n, o_ddr3_cke, o_ddr3_cs_n;
  wire o_ddr3_ras_n, o_ddr3_cas_n, o_ddr3_we_n, o_ddr3_odt;
  wire [ROW_BITS-1:0]           o_ddr3_addr;
  wire [BA_BITS-1:0]            o_ddr3_ba_addr;
  wire [DQ_BITS*BYTE_LANES-1:0] io_ddr3_dq;
  wire [BYTE_LANES-1:0]         io_ddr3_dqs, io_ddr3_dqs_n, o_ddr3_dm;
  wire o_calib_complete; wire [31:0] o_debug1; wire uart_tx;

  // ---- DUT: native Wishbone controller, BIST off ----
  ddr3_top #(
    .CONTROLLER_CLK_PERIOD(CONTROLLER_CLK_PERIOD), .DDR3_CLK_PERIOD(DDR3_CLK_PERIOD),
    .ROW_BITS(ROW_BITS), .COL_BITS(COL_BITS), .BA_BITS(BA_BITS), .BYTE_LANES(BYTE_LANES),
    .AUX_WIDTH(AUX_WIDTH), .MICRON_SIM(1), .ODELAY_SUPPORTED(0), .SECOND_WISHBONE(0),
    .WB_ERROR(0), .BIST_MODE(0), .ECC_ENABLE(0), .SELF_REFRESH(2'b00), .DUAL_RANK_DIMM(0), .DLL_OFF(0)
  ) dut (
    .i_controller_clk(i_controller_clk), .i_ddr3_clk(i_ddr3_clk), .i_ref_clk(i_ref_clk),
    .i_ddr3_clk_90(i_ddr3_clk_90), .i_rst_n(i_rst_n),
    .i_wb_cyc(i_wb_cyc), .i_wb_stb(i_wb_stb), .i_wb_we(i_wb_we), .i_wb_addr(i_wb_addr),
    .i_wb_data(i_wb_data), .i_wb_sel(i_wb_sel), .i_aux(i_aux),
    .o_wb_stall(o_wb_stall), .o_wb_ack(o_wb_ack), .o_wb_err(o_wb_err),
    .o_wb_data(o_wb_data), .o_aux(o_aux),
    .i_wb2_cyc(1'b0), .i_wb2_stb(1'b0), .i_wb2_we(1'b0), .i_wb2_addr('0),
    .i_wb2_data('0), .i_wb2_sel('0), .o_wb2_stall(), .o_wb2_ack(), .o_wb2_data(),
    .o_ddr3_clk_p(o_ddr3_clk_p), .o_ddr3_clk_n(o_ddr3_clk_n), .o_ddr3_reset_n(o_ddr3_reset_n),
    .o_ddr3_cke(o_ddr3_cke), .o_ddr3_cs_n(o_ddr3_cs_n), .o_ddr3_ras_n(o_ddr3_ras_n),
    .o_ddr3_cas_n(o_ddr3_cas_n), .o_ddr3_we_n(o_ddr3_we_n), .o_ddr3_addr(o_ddr3_addr),
    .o_ddr3_ba_addr(o_ddr3_ba_addr), .io_ddr3_dq(io_ddr3_dq), .io_ddr3_dqs(io_ddr3_dqs),
    .io_ddr3_dqs_n(io_ddr3_dqs_n), .o_ddr3_dm(o_ddr3_dm), .o_ddr3_odt(o_ddr3_odt),
    .o_calib_complete(o_calib_complete), .o_debug1(o_debug1),
    .i_user_self_refresh(1'b0), .uart_tx(uart_tx)
  );

  // ---- Micron x16 DDR3 model ----
  ddr3 #(.DLL_OFF(0)) ddr3_0 (
    .rst_n(o_ddr3_reset_n), .ck(o_ddr3_clk_p), .ck_n(o_ddr3_clk_n), .cke(o_ddr3_cke),
    .cs_n(o_ddr3_cs_n), .ras_n(o_ddr3_ras_n), .cas_n(o_ddr3_cas_n), .we_n(o_ddr3_we_n),
    .dm_tdqs(o_ddr3_dm), .ba(o_ddr3_ba_addr), .addr({2'b0, o_ddr3_addr}), .dq(io_ddr3_dq),
    .dqs(io_ddr3_dqs), .dqs_n(io_ddr3_dqs_n), .tdqs_n(), .odt(o_ddr3_odt)
  );

  // ---- watchdog ----
  initial begin #2_000_000_000;
    $display("SMOKE: TIMEOUT (calibration or traffic did not complete)"); $finish; end

  // ---- single-outstanding WB driver ----
  integer errors = 0;

  task automatic wb_write(input [WB_ADDR_BITS-1:0] a, input [WB_DATA_BITS-1:0] d);
    int wcnt;
    begin
      @(posedge i_controller_clk);
      i_wb_cyc<=1; i_wb_stb<=1; i_wb_we<=1; i_wb_addr<=a; i_wb_data<=d;
      i_wb_sel<={WB_SEL_BITS{1'b1}}; i_aux<=16'h1;
      // hold stb until the request is accepted (stb && !stall)
      wcnt=0; forever begin @(posedge i_controller_clk); if (!o_wb_stall) break;
                            wcnt++; if (wcnt>4000) begin $display("  [STALL] write-accept @ %0t",$time); errors++; break; end end
      i_wb_stb<=0;
      // wait for completion ack
      wcnt=0; forever begin @(posedge i_controller_clk); if (o_wb_ack) break;
                            wcnt++; if (wcnt>4000) begin $display("  [STALL] write-ack @ %0t",$time); errors++; break; end end
      i_wb_cyc<=0;
    end
  endtask

  task automatic wb_read(input [WB_ADDR_BITS-1:0] a, output [WB_DATA_BITS-1:0] d);
    int wcnt;
    begin
      @(posedge i_controller_clk);
      i_wb_cyc<=1; i_wb_stb<=1; i_wb_we<=0; i_wb_addr<=a; i_aux<=16'h2;
      wcnt=0; forever begin @(posedge i_controller_clk); if (!o_wb_stall) break;
                            wcnt++; if (wcnt>4000) begin $display("  [STALL] read-accept @ %0t",$time); errors++; break; end end
      i_wb_stb<=0;
      wcnt=0; forever begin @(posedge i_controller_clk); if (o_wb_ack) break;
                            wcnt++; if (wcnt>4000) begin $display("  [STALL] read-ack @ %0t",$time); errors++; break; end end
      d = o_wb_data;
      i_wb_cyc<=0;
    end
  endtask

  task automatic check(input [WB_ADDR_BITS-1:0] a, input [WB_DATA_BITS-1:0] d);
    reg [WB_DATA_BITS-1:0] r;
    begin
      wb_write(a, d);
      wb_read (a, r);
      if (r !== d) begin errors++; $display("  [FAIL] addr=%h exp=%h got=%h", a, d, r); end
      else                          $display("  [OK]   addr=%h data=%h", a, d);
    end
  endtask

  // ---- stimulus ----
  initial begin
    i_wb_cyc=0; i_wb_stb=0; i_wb_we=0; i_wb_addr=0; i_wb_data=0; i_wb_sel=0; i_aux=0;
    $display("==== UberDDR3 Wishbone smoke: waiting for calibration ====");
    wait (o_calib_complete === 1'b1);
    $display("==== calibration complete @ %0t ps ====", $time);
    repeat (10) @(posedge i_controller_clk);

    check(24'h00_0000, 128'hDEADBEEF_00112233_44556677_8899AABB);
    check(24'h00_0001, 128'h01234567_89ABCDEF_FEDCBA98_76543210);
    check(24'h00_0002, 128'hA5A5A5A5_5A5A5A5A_F0F0F0F0_0F0F0F0F);
    check(24'h00_0100, 128'h11111111_22222222_33333333_44444444);
    check(24'h10_0000, 128'hCAFEBABE_DEADC0DE_8BADF00D_FEEDFACE);

    repeat (20) @(posedge i_controller_clk);
    if (errors == 0) $display("SMOKE: PASS (all WB writes/reads matched)");
    else             $display("SMOKE: FAIL (%0d errors)", errors);
    $finish;
  end

endmodule : tb_top_wb
