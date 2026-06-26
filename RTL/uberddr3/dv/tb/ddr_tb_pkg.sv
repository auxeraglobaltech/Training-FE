// ============================================================================
//  ddr_tb_pkg.sv  —  packages the UberDDR3 Wishbone UVM testbench classes
//  (include paths are relative to dv/tb, supplied via +incdir+dv/tb)
// ============================================================================
`timescale 1ps/1ps
package ddr_tb_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  // ---- transaction ----
  `include "agents/wb_seq_item.sv"
  // ---- agent ----
  `include "agents/wb_master_driver.sv"
  `include "agents/wb_monitor.sv"
  `include "agents/wb_master_agent.sv"
  // ---- env ----
  `include "env/ddr_scoreboard.sv"
  `include "env/ddr_coverage.sv"
  `include "env/ddr_env.sv"
  // ---- sequences ----
  `include "seq/ddr_sequences.sv"
  // ---- tests ----
  `include "tests/ddr_base_test.sv"
  `include "tests/ddr_sanity_test.sv"
  `include "tests/ddr_random_test.sv"
  `include "tests/ddr_bytesel_test.sv"
  `include "tests/ddr_walk_test.sv"
  `include "tests/ddr_refresh_test.sv"

endpackage : ddr_tb_pkg
