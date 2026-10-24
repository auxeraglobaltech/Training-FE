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

  // SV -> C mailbox registers (TB I/O page, sw/common/memmap.h). Driven
  // by ibex_c2sv_mbox; tb_top returns them on data-bus reads of
  // SV2C_ACK (0x30018) / SV2C_DATA (0x3001C).
  logic [31:0] sv2c_ack;
  logic [31:0] sv2c_data;

  // Sampling point for every passive bus tap in the env (monitor,
  // console, c2sv mailbox, driver's irq_ctrl watcher). Inputs are
  // sampled just before the clock edge (#1step), i.e. the values that
  // were stable during the cycle - so a tap can never race with the DUT
  // updating the bus in the same timestep as the edge it wakes on.
  clocking mon_cb @(posedge clk);
    default input #1step;
    input data_req, data_gnt, data_we, data_be, data_addr, data_wdata;
  endclocking

endinterface
