`timescale 1ns/1ps
module top;
  import uvm_pkg::*;
  import pkg::*;
 `include "uvm_macros.svh"
  logic clk;
  initial clk=0;
  always #5 clk=~clk;
  initial begin
    vif.rst_n = 0;
    #5; 
   vif.rst_n = 1;
  end
  agu_if vif(clk);
   initial begin
  uvm_config_db#(virtual agu_if)::set(null,"*","vif",vif);
  end
   rtddma_agutop DUT(
      .clk                  (clk),
      .rst_n                (vif.rst_n),

      //Control

      .start_i              (vif.start_i),
      .stop_i               (vif.stop_i),
      .clr_fault_i          (vif.clr_fault_i),
      
      //Descriptor

      .desc_w0_i            (vif.desc_w0_i),
      .desc_w1_i            (vif.desc_w1_i),
      .desc_w2_i            (vif.desc_w2_i),
      .desc_w3_i            (vif.desc_w3_i),
      .desc_w4_i            (vif.desc_w4_i),
      .desc_w5_i            (vif.desc_w5_i),
      .desc_w6_i            (vif.desc_w6_i),

      //MPU Region
    
      .src_region_base_i    (vif.src_region_base_i),
      .src_region_limit_i   (vif.src_region_limit_i),

      .dst_region_base_i    (vif.dst_region_base_i),
      .dst_region_limit_i   (vif.dst_region_limit_i),

      //Issue Interface

      .issue_ready_i        (vif.issue_ready_i),
      .issue_ack_i          (vif.issue_ack_i),

      .outstanding_cnt_i    (vif.outstanding_cnt_i),

      //Outputs

      .agu_valid_o          (vif.agu_valid_o),
      .agu_src_addr_o       (vif.agu_src_addr_o),
      .agu_dst_addr_o       (vif.agu_dst_addr_o),

      .agu_burst_bytes_o    (vif.agu_burst_bytes_o),

      .agu_busy_o           (vif.agu_busy_o),
      .agu_done_o           (vif.agu_done_o),

      //Fault

      .fault_valid_o        (vif.fault_valid_o),
      .fault_code_o         (vif.fault_code_o),
      .fault_info_o         (vif.fault_info_o)

                );

    initial begin
  run_test("");
  end

  initial begin
    $shm_open("wave.shm");
    $shm_probe("ACTMF");
  end
endmodule

