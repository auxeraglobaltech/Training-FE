`timescale 1ns/1ps
import uvm_pkg::*;
`include "uvm_macros.svh"
import ibex_pkg::*;
import ibex_test_pkg::*;

module tb_top;

  // Clock
  logic clk = 0;
  always #5 clk = ~clk;

  // Interface
  ibex_if u_if(.clk(clk));

  // -------------------------------------------------------
  // Byte-addressed SRAM
  // Covers ROM 0x00000000-0x0000FFFF (64 KB)
  // and  RAM 0x00010000-0x0003FFFF (192 KB)
  // -------------------------------------------------------
  logic [7:0] mem_b [0:262143];   // 256 KB total
  initial begin
    // initialise to 0 so unloaded locations return NOP (addi x0,x0,0)
    for (int i = 0; i < 262144; i++) mem_b[i] = 8'h0;
    $readmemh("sim/hello_world.vmem", mem_b);
  end

  // Little-endian word read
  function automatic logic [31:0] read_word(input logic [31:0] addr);
    logic [31:0] a;
    a = {addr[31:2], 2'b00};
    return {mem_b[a+3], mem_b[a+2], mem_b[a+1], mem_b[a+0]};
  endfunction

  // -------------------------------------------------------
  // Local pipeline registers for memory responses
  // (keeps ibex assertions happy: rvalid/rdata must be
  //  stable, known, and come exactly 1 cycle after grant)
  // -------------------------------------------------------
  logic        instr_rvalid_r;
  logic [31:0] instr_rdata_r;
  logic        data_rvalid_r;
  logic [31:0] data_rdata_r;

  // Combinatorial grants: zero-wait-state memory
  assign u_if.instr_gnt = u_if.instr_req;
  assign u_if.instr_err = 1'b0;
  assign u_if.data_gnt  = u_if.data_req;
  assign u_if.data_err  = 1'b0;

  // Drive rvalid / rdata from registered locals
  assign u_if.instr_rvalid = instr_rvalid_r;
  assign u_if.instr_rdata  = instr_rdata_r;
  assign u_if.data_rvalid  = data_rvalid_r;
  assign u_if.data_rdata   = data_rdata_r;

  // Instruction memory — registered 1-cycle response, reset clears rvalid
  always @(posedge clk or negedge u_if.rst_n) begin
    if (!u_if.rst_n) begin
      instr_rvalid_r <= 1'b0;
      instr_rdata_r  <= 32'h0;
    end else begin
      instr_rvalid_r <= u_if.instr_req;
      instr_rdata_r  <= read_word(u_if.instr_addr);
    end
  end

  // Data memory — registered 1-cycle response, reset clears rvalid
  always @(posedge clk or negedge u_if.rst_n) begin
    if (!u_if.rst_n) begin
      data_rvalid_r <= 1'b0;
      data_rdata_r  <= 32'h0;
    end else begin
      data_rvalid_r <= u_if.data_req;
      // Write path (blocking so read-after-write in same cycle sees new data)
      if (u_if.data_req && u_if.data_we) begin
        if (u_if.data_be[0]) mem_b[{u_if.data_addr[31:2],2'b00}+0] = u_if.data_wdata[ 7: 0];
        if (u_if.data_be[1]) mem_b[{u_if.data_addr[31:2],2'b00}+1] = u_if.data_wdata[15: 8];
        if (u_if.data_be[2]) mem_b[{u_if.data_addr[31:2],2'b00}+2] = u_if.data_wdata[23:16];
        if (u_if.data_be[3]) mem_b[{u_if.data_addr[31:2],2'b00}+3] = u_if.data_wdata[31:24];
      end
      data_rdata_r <= read_word(u_if.data_addr);
    end
  end

  // -------------------------------------------------------
  // DUT
  // -------------------------------------------------------
  ibex_top #(
    .RV32M          (ibex_pkg::RV32MFast),
    .RV32B          (ibex_pkg::RV32BNone),
    .RegFile        (ibex_pkg::RegFileFF),
    .SecureIbex     (1'b0),
    .ICache         (1'b0),
    .ICacheECC      (1'b0),
    .WritebackStage (1'b0)
  ) u_ibex (
    .clk_i                    (clk),
    .rst_ni                   (u_if.rst_n),

    .test_en_i                (1'b0),
    .ram_cfg_icache_tag_i     ('0),
    .ram_cfg_rsp_icache_tag_o (),
    .ram_cfg_icache_data_i    ('0),
    .ram_cfg_rsp_icache_data_o(),

    .hart_id_i                (32'h0),
    .boot_addr_i              (32'h0),

    // Instruction memory
    .instr_req_o              (u_if.instr_req),
    .instr_gnt_i              (u_if.instr_gnt),
    .instr_rvalid_i           (u_if.instr_rvalid),
    .instr_addr_o             (u_if.instr_addr),
    .instr_rdata_i            (u_if.instr_rdata),
    .instr_rdata_intg_i       (7'h0),
    .instr_err_i              (1'b0),

    // Data memory
    .data_req_o               (u_if.data_req),
    .data_gnt_i               (u_if.data_gnt),
    .data_rvalid_i            (u_if.data_rvalid),
    .data_we_o                (u_if.data_we),
    .data_be_o                (u_if.data_be),
    .data_addr_o              (u_if.data_addr),
    .data_wdata_o             (u_if.data_wdata),
    .data_wdata_intg_o        (),
    .data_rdata_i             (u_if.data_rdata),
    .data_rdata_intg_i        (7'h0),
    .data_err_i               (1'b0),

    // Interrupts
    .irq_software_i           (1'b0),
    .irq_timer_i              (u_if.irq_timer),
    .irq_external_i           (u_if.irq_external),
    .irq_fast_i               (u_if.irq_fast),
    .irq_nm_i                 (1'b0),

    // Scrambling (tied off)
    .scramble_key_valid_i     (1'b0),
    .scramble_key_i           ('0),
    .scramble_nonce_i         ('0),
    .scramble_req_o           (),

    // Debug
    .debug_req_i              (u_if.debug_req),
    .crash_dump_o             (),
    .double_fault_seen_o      (),

    // Control
    .fetch_enable_i           (ibex_pkg::IbexMuBiOn),
    .alert_minor_o            (),
    .alert_major_internal_o   (),
    .alert_major_bus_o        (),
    .core_sleep_o             (),

    // DFT
    .scan_rst_ni              (1'b1),

    // Lockstep / shadow outputs
    .lockstep_cmp_en_o        (),
    .data_req_shadow_o        (),
    .data_we_shadow_o         (),
    .data_be_shadow_o         (),
    .data_addr_shadow_o       (),
    .data_wdata_shadow_o      (),
    .data_wdata_intg_shadow_o (),
    .instr_req_shadow_o       (),
    .instr_addr_shadow_o      ()
  );

  // -------------------------------------------------------
  // tohost monitor
  // -------------------------------------------------------
  always @(posedge clk) begin
    if (u_if.data_req && u_if.data_we &&
        {u_if.data_addr[31:2], 2'b00} == 32'h00010000) begin
      if (u_if.data_wdata == 32'h1)
        `uvm_info("TOHOST", "TEST PASSED", UVM_NONE)
      else
        `uvm_error("TOHOST", "TEST FAILED")
      fork
        begin #100; $finish; end
      join_none
    end
  end

  // -------------------------------------------------------
  // Wave dumping  (enabled with +DUMP_WAVES on xrun command line)
  // Path set by +SHM_PATH=<dir>/waves.shm  (default: waves.shm)
  // -------------------------------------------------------
  initial begin
    if ($test$plusargs("DUMP_WAVES")) begin
      $shm_open("waves.shm");
      $shm_probe("ACTMF");
      `uvm_info("WAVES", "Dumping waves to: waves.shm", UVM_NONE)
    end
  end

  initial begin
    uvm_config_db#(virtual ibex_if)::set(null, "*", "vif", u_if);
    run_test();
  end

endmodule
