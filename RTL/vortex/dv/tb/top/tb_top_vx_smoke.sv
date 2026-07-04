// ============================================================
//  tb_top_vx_smoke — Phase 2 directed (non-UVM) boot smoke for Vortex 1-core.
//
//  Implements the sim/rtlsim/{main,processor}.cpp contract natively in SV
//  (see dv/docs/boot_dcr_notes.md):
//    1. preload +KERNEL=<hex> into a sparse byte memory (base 0x8000_0000)
//    2. reset 8 cycles + 8 settle
//    3. write the KMU boot DCRs (startup addr, grid/block dims, warp step)
//    4. pulse start; wait busy rise then fall
//    5. flush caches (DCR read of VX_DCR_BASE_CACHE_FLUSH, tag = core id)
//    6. check 32-bit exit code at VX_MEM_IO_EXIT_CODE (0x8348): 0 = PASS
//
//  Memory responder: banked, always-ready, fixed RSP_LATENCY, in-order queue.
//  INTERLEAVE=1 address reconstruction: (addr*NUM_BANKS + b) * DATA_SIZE.
// ============================================================
`timescale 1ns/1ps

module tb_top_vx_smoke;

  // ---- mirrors rtlsim_shim parameters (from dv/shim/VX_config.vh) ----
  localparam int DATA_SIZE      = `VX_CFG_PLATFORM_MEMORY_DATA_SIZE;   // 64 bytes
  localparam int MEM_DATA_WIDTH = DATA_SIZE * 8;                       // 512
  localparam int MEM_NUM_BANKS  = `VX_CFG_PLATFORM_MEMORY_NUM_BANKS;   // 2
  localparam int MEM_ADDR_WIDTH = `VX_CFG_PLATFORM_MEMORY_ADDR_WIDTH
                                  - $clog2(MEM_NUM_BANKS);             // 31
  localparam int MEM_TAG_WIDTH  = 64;
  localparam int DCR_ADDR_WIDTH = 12;
  localparam int DCR_DATA_WIDTH = 32;

  localparam int RESET_CYCLES   = `VX_CFG_RESET_DELAY;                 // 8
  localparam int RSP_LATENCY    = 4;        // fixed DRAM-ish latency (cycles)
  localparam longint WATCHDOG_CYCLES = 2_000_000;

  // VX_types.vh constants (documented in boot_dcr_notes.md)
  localparam [11:0] DCR_BASE_CACHE_FLUSH  = 12'h000;
  localparam [11:0] KMU_STARTUP_ADDR0     = 12'h010;
  localparam [11:0] KMU_STARTUP_ARG0      = 12'h014;
  localparam [11:0] KMU_STARTUP_ARG1      = 12'h015;
  localparam [11:0] KMU_BLOCK_DIM_X       = 12'h016;
  localparam [11:0] KMU_BLOCK_DIM_Y       = 12'h017;
  localparam [11:0] KMU_BLOCK_DIM_Z       = 12'h018;
  localparam [11:0] KMU_GRID_DIM_X        = 12'h019;
  localparam [11:0] KMU_GRID_DIM_Y        = 12'h01A;
  localparam [11:0] KMU_GRID_DIM_Z        = 12'h01B;
  localparam [11:0] KMU_LMEM_SIZE         = 12'h01C;
  localparam [11:0] KMU_BLOCK_SIZE        = 12'h01D;
  localparam [11:0] KMU_WARP_STEP_X       = 12'h01E;
  localparam [11:0] KMU_WARP_STEP_Y       = 12'h01F;
  localparam [11:0] KMU_WARP_STEP_Z       = 12'h020;
  localparam [11:0] KMU_CLUSTER_DIM_X     = 12'h021;
  localparam [11:0] KMU_CLUSTER_DIM_Y     = 12'h022;
  localparam [11:0] KMU_CLUSTER_DIM_Z     = 12'h023;

  localparam longint unsigned MEM_IO_EXIT_CODE = 64'h8348;   // 33608
  localparam [31:0] STARTUP_ADDR = 32'h8000_0000;

  // ---- clock / reset ----
  logic clk = 0;
  logic reset = 1;
  always #5 clk = ~clk;   // 100 MHz

  // ---- DUT interface nets ----
  wire                          mem_req_valid  [MEM_NUM_BANKS];
  wire                          mem_req_rw     [MEM_NUM_BANKS];
  wire [DATA_SIZE-1:0]          mem_req_byteen [MEM_NUM_BANKS];
  wire [MEM_ADDR_WIDTH-1:0]     mem_req_addr   [MEM_NUM_BANKS];
  wire [MEM_DATA_WIDTH-1:0]     mem_req_data   [MEM_NUM_BANKS];
  wire [MEM_TAG_WIDTH-1:0]      mem_req_tag    [MEM_NUM_BANKS];
  logic                         mem_req_ready  [MEM_NUM_BANKS];

  logic                         mem_rsp_valid  [MEM_NUM_BANKS];
  logic [MEM_DATA_WIDTH-1:0]    mem_rsp_data   [MEM_NUM_BANKS];
  logic [MEM_TAG_WIDTH-1:0]     mem_rsp_tag    [MEM_NUM_BANKS];
  wire                          mem_rsp_ready  [MEM_NUM_BANKS];

  logic                         dcr_req_valid = 0;
  logic                         dcr_req_rw    = 0;
  logic [DCR_ADDR_WIDTH-1:0]    dcr_req_addr  = '0;
  logic [DCR_DATA_WIDTH-1:0]    dcr_req_data  = '0;
  wire                          dcr_rsp_valid;
  wire [DCR_DATA_WIDTH-1:0]     dcr_rsp_data;

  logic                         start = 0;
  wire                          busy;

  rtlsim_shim dut (
    .clk            (clk),
    .reset          (reset),
    .mem_req_valid  (mem_req_valid),
    .mem_req_rw     (mem_req_rw),
    .mem_req_byteen (mem_req_byteen),
    .mem_req_addr   (mem_req_addr),
    .mem_req_data   (mem_req_data),
    .mem_req_tag    (mem_req_tag),
    .mem_req_ready  (mem_req_ready),
    .mem_rsp_valid  (mem_rsp_valid),
    .mem_rsp_data   (mem_rsp_data),
    .mem_rsp_tag    (mem_rsp_tag),
    .mem_rsp_ready  (mem_rsp_ready),
    .dcr_req_valid  (dcr_req_valid),
    .dcr_req_rw     (dcr_req_rw),
    .dcr_req_addr   (dcr_req_addr),
    .dcr_req_data   (dcr_req_data),
    .dcr_rsp_valid  (dcr_rsp_valid),
    .dcr_rsp_data   (dcr_rsp_data),
    .start          (start),
    .busy           (busy)
  );

  // ============================================================
  //  Sparse backing store (byte-addressed) + program load
  // ============================================================
  logic [7:0] mem [longint unsigned];

  function automatic logic [7:0] mem_rd_byte(longint unsigned a);
    return mem.exists(a) ? mem[a] : 8'h00;
  endfunction

  // ============================================================
  //  Banked memory responder — in-order queue + fixed latency
  // ============================================================
  typedef struct {
    logic [MEM_DATA_WIDTH-1:0] data;
    logic [MEM_TAG_WIDTH-1:0]  tag;
    longint unsigned           due;    // cycle when response may be driven
  } rsp_t;

  longint unsigned cycle = 0;
  always @(posedge clk) cycle <= cycle + 1;

  rsp_t rsp_q [MEM_NUM_BANKS][$];

  // traffic counters: a "completed" run with zero fetches is a false PASS
  longint unsigned n_mem_rd = 0, n_mem_wr = 0;

  for (genvar b = 0; b < MEM_NUM_BANKS; b++) begin : g_bank
    // request side
    always @(posedge clk) begin
      if (reset) begin
        mem_req_ready[b] <= 1'b0;
      end else begin
        mem_req_ready[b] <= 1'b1;
        if (mem_req_valid[b] && mem_req_ready[b]) begin
          longint unsigned byte_addr;
          byte_addr = (longint'(mem_req_addr[b]) * MEM_NUM_BANKS + b) * DATA_SIZE;
          if (mem_req_rw[b]) begin
            n_mem_wr++;
            for (int i = 0; i < DATA_SIZE; i++)
              if (mem_req_byteen[b][i])
                mem[byte_addr + i] = mem_req_data[b][i*8 +: 8];
          end else begin
            rsp_t r;
            n_mem_rd++;
            for (int i = 0; i < DATA_SIZE; i++)
              r.data[i*8 +: 8] = mem_rd_byte(byte_addr + i);
            r.tag = mem_req_tag[b];
            r.due = cycle + RSP_LATENCY;
            rsp_q[b].push_back(r);
          end
        end
      end
    end
    // response side (in-order, hold until accepted)
    always @(posedge clk) begin
      if (reset) begin
        mem_rsp_valid[b] <= 1'b0;
      end else begin
        if (mem_rsp_valid[b] && mem_rsp_ready[b])
          mem_rsp_valid[b] <= 1'b0;
        if (!(mem_rsp_valid[b] && !mem_rsp_ready[b])) begin
          if (rsp_q[b].size() > 0 && rsp_q[b][0].due <= cycle) begin
            mem_rsp_valid[b] <= 1'b1;
            mem_rsp_data[b]  <= rsp_q[b][0].data;
            mem_rsp_tag[b]   <= rsp_q[b][0].tag;
            rsp_q[b].pop_front();
          end
        end
      end
    end
  end

  // ============================================================
  //  DCR master tasks
  // ============================================================
  task automatic dcr_write(input [11:0] addr, input [31:0] data);
    @(negedge clk);
    dcr_req_valid = 1'b1; dcr_req_rw = 1'b1;
    dcr_req_addr  = addr; dcr_req_data = data;
    @(negedge clk);
    dcr_req_valid = 1'b0; dcr_req_rw = 1'b0;
  endtask

  task automatic dcr_read(input [11:0] addr, input [31:0] tag,
                          output [31:0] data);
    @(negedge clk);
    dcr_req_valid = 1'b1; dcr_req_rw = 1'b0;
    dcr_req_addr  = addr; dcr_req_data = tag;
    @(negedge clk);
    dcr_req_valid = 1'b0;
    while (!dcr_rsp_valid) @(negedge clk);
    data = dcr_rsp_data;
  endtask

  // ============================================================
  //  Test sequence
  // ============================================================
  string kernel_path;
  logic [31:0] exit_code, flush_rsp;

  initial begin
    if (!$value$plusargs("KERNEL=%s", kernel_path)) begin
      $display("SMOKE: [FAIL] no +KERNEL=<hex> given");
      $finish;
    end
    $display("SMOKE: loading kernel image: %s", kernel_path);
    $readmemh(kernel_path, mem);

    // reset: 8 cycles asserted + 8 settle (processor.cpp reset())
    reset = 1'b1;
    repeat (RESET_CYCLES) @(negedge clk);
    reset = 1'b0;
    repeat (RESET_CYCLES) @(negedge clk);
    $display("SMOKE: reset done @%0t", $time);

    // boot DCR programming (main.cpp)
    dcr_write(KMU_STARTUP_ADDR0, STARTUP_ADDR);
    dcr_write(KMU_STARTUP_ARG0,  32'd0);
    dcr_write(KMU_STARTUP_ARG1,  32'd0);
    dcr_write(KMU_BLOCK_DIM_X,   32'd1);
    dcr_write(KMU_BLOCK_DIM_Y,   32'd1);
    dcr_write(KMU_BLOCK_DIM_Z,   32'd1);
    dcr_write(KMU_GRID_DIM_X,    32'd1);
    dcr_write(KMU_GRID_DIM_Y,    32'd1);
    dcr_write(KMU_GRID_DIM_Z,    32'd1);
    dcr_write(KMU_LMEM_SIZE,     32'd0);
    dcr_write(KMU_BLOCK_SIZE,    32'd1);
    dcr_write(KMU_WARP_STEP_X,   `VX_CFG_NUM_THREADS);
    dcr_write(KMU_WARP_STEP_Y,   32'd0);
    dcr_write(KMU_WARP_STEP_Z,   32'd0);
    dcr_write(KMU_CLUSTER_DIM_X, 32'd1);
    dcr_write(KMU_CLUSTER_DIM_Y, 32'd1);
    dcr_write(KMU_CLUSTER_DIM_Z, 32'd1);
    $display("SMOKE: DCR boot programming done @%0t", $time);

    // start pulse (1 cycle)
    @(negedge clk); start = 1'b1;
    @(negedge clk); start = 1'b0;

    // wait busy rise then fall; treat re-assertion within IDLE_CONFIRM cycles
    // as the same run (kmu_busy / cluster busy can be discontinuous)
    fork : busy_wait
      begin
        int idle;
        wait (busy === 1'b1);
        $display("SMOKE: busy asserted @%0t", $time);
        idle = 0;
        while (idle < 100) begin
          @(posedge clk);
          if (busy === 1'b0) idle++;
          else               idle = 0;
        end
        $display("SMOKE: busy deasserted (stable) @%0t (cycle %0d)", $time, cycle);
        disable busy_wait;
      end
      begin
        repeat (WATCHDOG_CYCLES) @(posedge clk);
        $display("SMOKE: [FAIL] watchdog: busy did not complete in %0d cycles",
                 WATCHDOG_CYCLES);
        $finish;
      end
    join_any

    // flush caches: DCR read of BASE_CACHE_FLUSH per core (tag = core id)
    dcr_read(DCR_BASE_CACHE_FLUSH, 32'd0, flush_rsp);
    repeat (100) @(negedge clk);   // let writebacks drain to the responder

    // readback: exit code (0 = PASS) + done magic @0x8350 (proves execution;
    // unwritten memory reads back 0 and cannot masquerade as a pass)
    begin
      logic [31:0] done_flag;
      for (int i = 0; i < 4; i++) begin
        exit_code[i*8 +: 8] = mem_rd_byte(MEM_IO_EXIT_CODE + i);
        done_flag[i*8 +: 8] = mem_rd_byte(MEM_IO_EXIT_CODE + 8 + i);
      end
      $display("SMOKE: EXITCODE = 0x%08h DONE = 0x%08h (mem reads=%0d writes=%0d)",
               exit_code, done_flag, n_mem_rd, n_mem_wr);
      if (n_mem_rd == 0)
        $display("SMOKE: [FAIL] core issued no memory reads — kernel never fetched");
      else if (done_flag != 32'h600D_C0DE)
        $display("SMOKE: [FAIL] done flag not set — kernel never completed");
      else if (exit_code == 32'h0)
        $display("SMOKE: [OK] kernel ran to completion, exit code 0");
      else
        $display("SMOKE: [FAIL] non-zero exit code 0x%08h", exit_code);
    end
    $finish;
  end

endmodule
