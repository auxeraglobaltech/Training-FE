// ============================================================================
//  filelist_axi.f — AXI4 build (ddr3_top_axi + Micron model + our harness)
//  Paths relative to RTL/uberddr3 (Makefile invokes xrun from there).
//  Vendor-free: SIM_MODEL selects the bundled behavioral PHY primitive models.
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

// ---- UberDDR3 core (controller via Xcelium shim) ----
rtl/ddr3_top.v
dv/shim/ddr3_controller.sv
rtl/ddr3_phy.v
rtl/ecc/ecc_enc.sv
rtl/ecc/ecc_dec.sv

// ---- AXI4 wrapper + AXI-to-Wishbone bridge ----
rtl/axi/skidbuffer.v
rtl/axi/sfifo.v
rtl/axi/axi_addr.v
rtl/axi/aximrd2wbsp.v
// Xcelium X-immune shim for the write bridge (see header); replaces rtl/axi/aximwr2wbsp.v
dv/shim/aximwr2wbsp.v
rtl/axi/wbarbiter.v
rtl/axi/axim2wbsp.v
// Xcelium integration shim: gates the AXI bridge reset on calibration (see header).
// Replaces rtl/axi/ddr3_top_axi.v.
dv/shim/ddr3_top_axi.v

// ---- Micron DDR3 model (x16 single device, TWO_LANES_x8) ----
testbench/ddr3.sv

// ---- our directed AXI smoke harness (top) ----
dv/tb/top/tb_top_axi.sv
