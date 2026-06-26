// ============================================================================
//  filelist_wb_smoke.f — directed Wishbone smoke (native ddr3_top + Micron model)
//  Paths relative to RTL/uberddr3. Vendor-free (SIM_MODEL behavioral models).
//  No AXI wrapper/bridge — drives the controller's native Wishbone interface.
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

// ---- Micron DDR3 model (x16, TWO_LANES_x8) ----
testbench/ddr3.sv

// ---- our directed Wishbone smoke harness (top) ----
dv/tb/top/tb_top_wb.sv
