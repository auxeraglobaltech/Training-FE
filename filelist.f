// ============================================================
// Include paths for prim_assert.sv (included via `include)
// ============================================================
+incdir+RTL/ibex/vendor/lowrisc_ip/ip/prim/rtl

// ============================================================
// Primitive packages (must come first)
// ============================================================
RTL/ibex/vendor/lowrisc_ip/ip/prim/rtl/prim_util_pkg.sv
RTL/ibex/vendor/lowrisc_ip/ip/prim/rtl/prim_mubi_pkg.sv
RTL/ibex/vendor/lowrisc_ip/ip/prim/rtl/prim_secded_pkg.sv
RTL/ibex/vendor/lowrisc_ip/ip/prim/rtl/prim_cipher_pkg.sv
RTL/ibex/vendor/lowrisc_ip/ip/prim/rtl/prim_count_pkg.sv
RTL/ibex/vendor/lowrisc_ip/ip/prim_generic/rtl/prim_ram_1p_pkg.sv

// ============================================================
// ibex package (must precede all ibex RTL)
// ============================================================
RTL/ibex/rtl/ibex_pkg.sv

// ============================================================
// Primitive generic implementations
// ============================================================
RTL/ibex/vendor/lowrisc_ip/ip/prim_generic/rtl/prim_buf.sv
RTL/ibex/vendor/lowrisc_ip/ip/prim_generic/rtl/prim_flop.sv
RTL/ibex/vendor/lowrisc_ip/ip/prim_generic/rtl/prim_clock_gating.sv
RTL/ibex/vendor/lowrisc_ip/ip/prim_generic/rtl/prim_ram_1p.sv

// prim_flop_macros needed by some ibex RTL
RTL/ibex/vendor/lowrisc_ip/ip/prim/rtl/prim_flop_macros.sv

// ============================================================
// ibex RTL files
// ============================================================
RTL/ibex/rtl/ibex_alu.sv
RTL/ibex/rtl/ibex_branch_predict.sv
RTL/ibex/rtl/ibex_compressed_decoder.sv
RTL/ibex/rtl/ibex_controller.sv
RTL/ibex/rtl/ibex_core.sv
RTL/ibex/rtl/ibex_counter.sv
RTL/ibex/rtl/ibex_cs_registers.sv
RTL/ibex/rtl/ibex_csr.sv
RTL/ibex/rtl/ibex_decoder.sv
RTL/ibex/rtl/ibex_dummy_instr.sv
RTL/ibex/rtl/ibex_ex_block.sv
RTL/ibex/rtl/ibex_fetch_fifo.sv
RTL/ibex/rtl/ibex_icache.sv
RTL/ibex/rtl/ibex_id_stage.sv
RTL/ibex/rtl/ibex_if_stage.sv
RTL/ibex/rtl/ibex_load_store_unit.sv
RTL/ibex/rtl/ibex_lockstep.sv
RTL/ibex/rtl/ibex_multdiv_fast.sv
RTL/ibex/rtl/ibex_multdiv_slow.sv
RTL/ibex/rtl/ibex_pmp.sv
RTL/ibex/rtl/ibex_prefetch_buffer.sv
RTL/ibex/rtl/ibex_register_file_ff.sv
RTL/ibex/rtl/ibex_register_file_fpga.sv
RTL/ibex/rtl/ibex_register_file_latch.sv
RTL/ibex/rtl/ibex_wb_stage.sv
RTL/ibex/rtl/ibex_top.sv

// ============================================================
// Testbench files (order matters: interface -> pkg -> top)
// ============================================================
tb/top/ibex_if.sv
tb/tests/ibex_pkg.sv
tb/top/tb_top.sv
