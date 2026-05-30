interface ibex_if(input logic clk);
  logic        rst_n;

  // Instruction memory interface
  logic        instr_req;
  logic        instr_gnt;
  logic        instr_rvalid;
  logic        instr_err;
  logic [31:0] instr_addr;
  logic [31:0] instr_rdata;

  // Data memory interface
  logic        data_req;
  logic        data_gnt;
  logic        data_rvalid;
  logic        data_we;
  logic        data_err;
  logic [3:0]  data_be;
  logic [31:0] data_addr;
  logic [31:0] data_wdata;
  logic [31:0] data_rdata;

  // Interrupt inputs
  logic        irq_software;
  logic        irq_timer;
  logic        irq_external;
  logic        irq_nm;
  logic [14:0] irq_fast;

  // Debug
  logic        debug_req;

endinterface
