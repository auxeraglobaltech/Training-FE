// ============================================================
//  vx_tb_pkg — Vortex single-core UVM testbench package.
//  Compile after the interfaces; requires VX_config.vh macros (incdir).
// ============================================================
`include "VX_config.vh"
`include "uvm_macros.svh"

// bytes per memory beat (used inside classes; from the frozen config)
`define VX_MEM_DATA_SIZE `VX_CFG_PLATFORM_MEMORY_DATA_SIZE

package vx_tb_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  `include "agents/vx_mem_agent.sv"
  `include "agents/vx_dcr_agent.sv"
  `include "agents/vx_ctrl_agent.sv"
  `include "seq/vx_sequences.sv"
  `include "env/vx_scoreboard.sv"
  `include "env/vx_coverage.sv"
  `include "env/vx_env.sv"
  `include "tests/vx_base_test.sv"
  `include "tests/vx_kernel_tests.sv"
endpackage
