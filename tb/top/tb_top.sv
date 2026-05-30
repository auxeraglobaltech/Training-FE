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

  // SRAM: 16 KB instruction / data memory
  logic [31:0] mem [0:16383];
  initial $readmemh("sim/hello_world.vmem", mem);

  // Instruction memory model
  always_ff @(posedge clk) begin
    u_if.instr_gnt    <= u_if.instr_req;
    u_if.instr_rvalid <= u_if.instr_gnt;
    u_if.instr_rdata  <= mem[u_if.instr_addr[15:2]];
    u_if.instr_err    <= 1'b0;
  end

  // Data memory model
  always_ff @(posedge clk) begin
    u_if.data_gnt    <= u_if.data_req;
    u_if.data_rvalid <= u_if.data_gnt;
    u_if.data_err    <= 1'b0;
    if (u_if.data_req && u_if.data_we) begin
      if (u_if.data_be[0]) mem[u_if.data_addr[15:2]][ 7: 0] <= u_if.data_wdata[ 7: 0];
      if (u_if.data_be[1]) mem[u_if.data_addr[15:2]][15: 8] <= u_if.data_wdata[15: 8];
      if (u_if.data_be[2]) mem[u_if.data_addr[15:2]][23:16] <= u_if.data_wdata[23:16];
      if (u_if.data_be[3]) mem[u_if.data_addr[15:2]][31:24] <= u_if.data_wdata[31:24];
    end
    u_if.data_rdata <= mem[u_if.data_addr[15:2]];
  end

  // DUT
  ibex_top #(
    .RV32M          (ibex_pkg::RV32MFast),
    .RV32B          (ibex_pkg::RV32BNone),
    .RegFile        (ibex_pkg::RegFileFF),
    .SecureIbex     (1'b0),
    .ICache         (1'b0),
    .ICacheECC      (1'b0),
    .WritebackStage (1'b0)
  ) u_ibex (
    .clk_i                   (clk),
    .rst_ni                  (u_if.rst_n),

    .test_en_i               (1'b0),
    .ram_cfg_icache_tag_i    ('0),
    .ram_cfg_rsp_icache_tag_o(),
    .ram_cfg_icache_data_i   ('0),
    .ram_cfg_rsp_icache_data_o(),

    .hart_id_i               (32'h0),
    .boot_addr_i             (32'h0),

    // Instruction memory
    .instr_req_o             (u_if.instr_req),
    .instr_gnt_i             (u_if.instr_gnt),
    .instr_rvalid_i          (u_if.instr_rvalid),
    .instr_addr_o            (u_if.instr_addr),
    .instr_rdata_i           (u_if.instr_rdata),
    .instr_rdata_intg_i      (7'h0),
    .instr_err_i             (1'b0),

    // Data memory
    .data_req_o              (u_if.data_req),
    .data_gnt_i              (u_if.data_gnt),
    .data_rvalid_i           (u_if.data_rvalid),
    .data_we_o               (u_if.data_we),
    .data_be_o               (u_if.data_be),
    .data_addr_o             (u_if.data_addr),
    .data_wdata_o            (u_if.data_wdata),
    .data_wdata_intg_o       (),
    .data_rdata_i            (u_if.data_rdata),
    .data_rdata_intg_i       (7'h0),
    .data_err_i              (1'b0),

    // Interrupts
    .irq_software_i          (1'b0),
    .irq_timer_i             (u_if.irq_timer),
    .irq_external_i          (u_if.irq_external),
    .irq_fast_i              (u_if.irq_fast),
    .irq_nm_i                (1'b0),

    // Scrambling (tied off)
    .scramble_key_valid_i    (1'b0),
    .scramble_key_i          ('0),
    .scramble_nonce_i        ('0),
    .scramble_req_o          (),

    // Debug
    .debug_req_i             (u_if.debug_req),
    .crash_dump_o            (),
    .double_fault_seen_o     (),

    // Control
    .fetch_enable_i          (ibex_pkg::IbexMuBiOn),
    .alert_minor_o           (),
    .alert_major_internal_o  (),
    .alert_major_bus_o       (),
    .core_sleep_o            (),

    // DFT
    .scan_rst_ni             (1'b1),

    // Lockstep / shadow outputs
    .lockstep_cmp_en_o       (),
    .data_req_shadow_o       (),
    .data_we_shadow_o        (),
    .data_be_shadow_o        (),
    .data_addr_shadow_o      (),
    .data_wdata_shadow_o     (),
    .data_wdata_intg_shadow_o(),
    .instr_req_shadow_o      (),
    .instr_addr_shadow_o     ()
  );

  // tohost monitor
  always_ff @(posedge clk) begin
    if (u_if.data_req && u_if.data_we && u_if.data_addr == 32'h00010000) begin
      if (u_if.data_wdata == 32'h1)
        `uvm_info("TOHOST", "TEST PASSED", UVM_NONE)
      else
        `uvm_error("TOHOST", "TEST FAILED")
      #100;
      $finish;
    end
  end

  initial begin
    uvm_config_db#(virtual ibex_if)::set(null, "*", "vif", u_if);
    run_test();
  end

endmodule
