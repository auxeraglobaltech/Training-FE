// ============================================================================
//  filelist.f  —  Xcelium compile order for the 2x2x2 NoC
//  Paths are relative to RTL/noc (xrun is invoked from there by the Makefile,
//  which also supplies +incdir+<RTL/noc> so `include "tb/..." resolves).
// ============================================================================

// ---- Package (must precede all RTL/TB that imports it) ----
RTL/noc_pkg.sv

// ---- Interfaces ----
tb/if/axi_if.sv
tb/if/apb_if.sv

// ---- RTL (DUT): leaf modules first, then the top integrator ----
RTL/noc_arbiter.sv
RTL/noc_axi_slave_port.sv
RTL/axi2apb_bridge.sv
RTL/noc_decerr_port.sv
RTL/noc_top.sv

// ---- SVA: arbiter checker + bind (AXI/APB assertions live in the interfaces) ----
tb/sva/arb_sva.sv
tb/sva/noc_bind.sv

// ---- Testbench package + top ----
tb/noc_tb_pkg.sv
tb/top/tb_top.sv
