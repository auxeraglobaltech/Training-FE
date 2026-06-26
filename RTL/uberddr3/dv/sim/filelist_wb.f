// ============================================================================
//  filelist_wb.f — Phase-0 Wishbone bring-up (UberDDR3 Micron testbench)
//  Ported from testbench/icarus_sim/sim_icarus.sh to Xcelium (xrun).
//  Paths are relative to RTL/uberddr3 (the Makefile invokes xrun from there).
//  Vendor-free: uses the bundled behavioral primitive models (SIM_MODEL),
//  so no Xilinx unisim / glbl is required.
// ============================================================================

+incdir+testbench

// ---- behavioral models of the Xilinx 7-series PHY primitives ----
testbench/models/IDELAYCTRL_model.v
testbench/models/IDELAYE2_model.v
testbench/models/IOBUF_DCIEN_model.v
testbench/models/IOBUF_model.v
testbench/models/IOBUFDS_DCIEN_model.v
testbench/models/IOBUFDS_model.v
testbench/models/ISERDESE2_model.v
testbench/models/OBUFDS_model.v
testbench/models/ODELAYE2_model.v
testbench/models/OSERDESE2_model.v
testbench/models/OBUF_model.v

// ---- UberDDR3 RTL (controller + PHY + wishbone top) ----
rtl/ddr3_top.v
// Xcelium constant-function compatibility shim (.sv = SV constant-function semantics);
// replaces rtl/ddr3_controller.v.  See dv/shim header for the exact edits.
dv/shim/ddr3_controller.sv
rtl/ddr3_phy.v
rtl/ecc/ecc_enc.sv
rtl/ecc/ecc_dec.sv

// ---- Micron DDR3 model + the bundled wishbone testbench (top) ----
testbench/ddr3.sv
testbench/ddr3_module.sv
testbench/ddr3_dimm_micron_sim.sv
