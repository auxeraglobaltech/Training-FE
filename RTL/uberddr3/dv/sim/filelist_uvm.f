// ============================================================================
//  filelist_uvm.f — UberDDR3 Wishbone UVM environment build
//  Paths relative to RTL/uberddr3. Vendor-free (SIM_MODEL behavioral models).
// ============================================================================

+incdir+testbench
+incdir+dv/tb

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

// ---- UberDDR3 core (controller via Xcelium constant-function shim) ----
rtl/ddr3_top.v
dv/shim/ddr3_controller.sv
rtl/ddr3_phy.v
rtl/ecc/ecc_enc.sv
rtl/ecc/ecc_dec.sv

// ---- Micron DDR3 model ----
testbench/ddr3.sv

// ---- UVM testbench: interface, package, top ----
dv/tb/if/wb_if.sv
dv/tb/ddr_tb_pkg.sv
dv/tb/top/tb_top_wb_uvm.sv
