// One banked-memory port of rtlsim_shim (one interface instance per bank).
`ifndef VX_MEM_IF_SV
`define VX_MEM_IF_SV

interface vx_mem_if #(
  parameter int DATA_SIZE  = 64,                 // bytes per beat
  parameter int ADDR_WIDTH = 31,                 // line address (bank bits removed)
  parameter int TAG_WIDTH  = 64
) (input logic clk, input logic reset);

  localparam int DATA_WIDTH = DATA_SIZE * 8;

  // request (DUT -> responder)
  logic                    req_valid;
  logic                    req_rw;
  logic [DATA_SIZE-1:0]    req_byteen;
  logic [ADDR_WIDTH-1:0]   req_addr;
  logic [DATA_WIDTH-1:0]   req_data;
  logic [TAG_WIDTH-1:0]    req_tag;
  logic                    req_ready;

  // response (responder -> DUT)
  logic                    rsp_valid;
  logic [DATA_WIDTH-1:0]   rsp_data;
  logic [TAG_WIDTH-1:0]    rsp_tag;
  logic                    rsp_ready;

endinterface

`endif
