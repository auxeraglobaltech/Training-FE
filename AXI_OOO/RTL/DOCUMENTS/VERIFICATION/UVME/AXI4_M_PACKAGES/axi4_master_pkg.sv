/***************************************************************************
File name:axi4_master_pkg.sv
Description: File contains the list of all the .sv files in various folders
***************************************************************************/

package pkg;

  import uvm_pkg::*;        
  `include "uvm_macros.svh"
         
  // Agent files: seq item, sequencer, driver, monitor, agent
  `include"../UVME/AXI4_M_SEQUENCES/axi4_master_seq_item.sv"
  `include"../UVME/AXI4_M_SEQUENCES/axi4_master_sequencer.sv"
  `include"../UVME/AXI4_M_AGENTS/axi4_master_driver.sv"
  `include"../UVME/AXI4_M_AGENTS/axi4_master_monitor.sv"
  `include"../UVME/AXI4_M_AGENTS/axi4_master_agent.sv"
  
  // Environment files: scoreboard, coverage, env
  `include "../UVME/AXI4_M_ENVIRONMENT/axi4_master_scoreboard.sv"
  `include "../UVME/AXI4_M_ENVIRONMENT/axi4_master_coverage.sv"
  `include "../UVME/AXI4_M_ENVIRONMENT/axi4_master_env.sv"
  
  // Sequence files
  `include"../UVME/AXI4_M_SEQUENCES/axi4_master_sequence.sv"
  
  // Tests
  `include"../UVME/AXI4_M_TESTS/axi4_m_base_test.sv"
  `include"../UVME/AXI4_M_TESTS/axi4_m_reset_test.sv"
  `include"../UVME/AXI4_M_TESTS/axi4_m_write_read_en_disable_test.sv"
  `include"../UVME/AXI4_M_TESTS/axi4_m_writeop_handshakefailure_test.sv"
  `include"../UVME/AXI4_M_TESTS/axi4_m_readop_handshakefailure_test.sv"
  `include"../UVME/AXI4_M_TESTS/axi4_m_writeop_deviceidfailure_test.sv"
  `include"../UVME/AXI4_M_TESTS/axi4_m_readop_deviceidfailure_test.sv"
  `include"../UVME/AXI4_M_TESTS/axi4_m_writeop_test.sv"
  `include"../UVME/AXI4_M_TESTS/axi4_m_random_writeop_test.sv"
  `include"../UVME/AXI4_M_TESTS/axi4_m_readop_test.sv"
  `include"../UVME/AXI4_M_TESTS/axi4_m_writeop_interleavingdata_test.sv"
  `include"../UVME/AXI4_M_TESTS/axi4_m_writeop_interleavingdata_timeout_test.sv"
//  `include"../test/.sv"
//  `include"../test/.sv"
//  `include"../test/.sv"
//  `include"../test/.sv"
//  `include"../test/.sv"
//  `include"../test/.sv"
//  `include"../test/.sv"
//  `include"../test/.sv"
//  `include"../test/.sv"
//  `include"../test/.sv"

endpackage
