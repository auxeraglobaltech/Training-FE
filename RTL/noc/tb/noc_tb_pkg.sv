// ============================================================================
//  noc_tb_pkg.sv  —  packages all NoC testbench classes
// ----------------------------------------------------------------------------
//  Include order: seq-items -> agents -> env (sb/cov/vseqr/env) -> sequences
//  -> tests.
// ============================================================================
`timescale 1ns/1ps
package noc_tb_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"
  import noc_pkg::*;

  // ---- transaction items ----
  `include "tb/agents/axi_seq_item.sv"
  `include "tb/agents/apb_seq_item.sv"

  // ---- agents / drivers / monitors ----
  `include "tb/agents/axi_master_driver.sv"
  `include "tb/agents/axi_monitor.sv"
  `include "tb/agents/axi_master_agent.sv"
  `include "tb/agents/axi_req_monitor.sv"
  `include "tb/agents/axi_slave_responder.sv"
  `include "tb/agents/apb_slave_responder.sv"
  `include "tb/agents/apb_monitor.sv"

  // ---- env infrastructure ----
  `include "tb/env/noc_scoreboard.sv"
  `include "tb/env/noc_coverage.sv"
  `include "tb/env/noc_vseqr.sv"
  `include "tb/env/noc_env.sv"

  // ---- sequences ----
  `include "tb/seq/noc_sequences.sv"

  // ---- tests ----
  `include "tb/tests/noc_base_test.sv"
  `include "tb/tests/noc_sanity_test.sv"
  `include "tb/tests/noc_decode_test.sv"
  `include "tb/tests/noc_random_test.sv"
  `include "tb/tests/noc_concurrency_test.sv"
  `include "tb/tests/noc_rr_arb_test.sv"
  `include "tb/tests/noc_priority_test.sv"
  `include "tb/tests/noc_bridge_test.sv"

endpackage : noc_tb_pkg
