interface agu_if(input logic clk);

   logic rst_n;
//control
   logic start_i;
   logic stop_i;
   logic clr_fault_i;

 //Descriptor words
   logic [31:0] desc_w0_i;
   logic [31:0] desc_w1_i;
   logic [31:0] desc_w2_i;
   logic [31:0] desc_w3_i;
   logic [31:0] desc_w4_i;
   logic [31:0] desc_w5_i;
   logic [31:0] desc_w6_i;

  //MPU region limits
   logic [39:0] src_region_base_i;
   logic [39:0] src_region_limit_i;
   logic [39:0] dst_region_base_i;
   logic [39:0] dst_region_limit_i;

 //Issue side Handcheck
   logic issue_ready_i;
   logic issue_ack_i;
   logic [3:0] outstanding_cnt_i;

//AGU Outputs
   logic agu_valid_o;
   logic [39:0] agu_src_addr_o;
   logic [39:0] agu_dst_addr_o;
   logic [15:0] agu_burst_bytes_o;

//Status
   logic agu_busy_o;
   logic agu_done_o;

//Faults
   logic fault_valid_o;
   logic [7:0] fault_code_o;
   logic [31:0] fault_info_o;

endinterface
