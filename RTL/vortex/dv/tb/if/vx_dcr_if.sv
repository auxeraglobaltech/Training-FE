// DCR (device configuration register) bus of rtlsim_shim: single-cycle
// writes, tagged reads with a response channel.
`ifndef VX_DCR_IF_SV
`define VX_DCR_IF_SV

interface vx_dcr_if #(
  parameter int ADDR_WIDTH = 12,
  parameter int DATA_WIDTH = 32
) (input logic clk, input logic reset);

  logic                    req_valid;
  logic                    req_rw;
  logic [ADDR_WIDTH-1:0]   req_addr;
  logic [DATA_WIDTH-1:0]   req_data;   // write data, or read tag
  logic                    rsp_valid;
  logic [DATA_WIDTH-1:0]   rsp_data;

endinterface

`endif
