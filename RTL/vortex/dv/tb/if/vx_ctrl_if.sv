// Control/status of rtlsim_shim: start pulse in, busy out.
`ifndef VX_CTRL_IF_SV
`define VX_CTRL_IF_SV

interface vx_ctrl_if (input logic clk, input logic reset);
  logic start;
  logic busy;
endinterface

`endif
