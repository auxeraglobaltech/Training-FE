// ============================================================
//  Vortex single-core (1 cluster x 1 core) — xrun source list
//
//  Mirrors sim/rtlsim/Makefile source discovery:
//   - generated headers come from build/hw (VX_config.vh, VX_types.vh)
//   - packages compiled explicitly, in dependency order
//   - remaining modules resolved by library search (-y) like the
//     Verilator flow's include-dir auto-discovery
//  DPI-free: SV_DPI is NOT defined; FPU forced to FPNEW (pure RTL).
// ============================================================

// ---- include dirs (resolved-config shim first, then generated headers) ----
// dv/shim/VX_config.vh is the FROZEN, fully-resolved 1-core FPNEW config
// (gen_config.py --resolved). It shadows build/hw/VX_config.vh, whose nested
// `__MIN/`__CLOG2 macros crash xmvlog (macro-recursion segfault).
-incdir ${VX_HOME}/dv/shim
-incdir ${VX_BUILD}/hw
-incdir ${VX_HOME}/hw/rtl
-incdir ${VX_HOME}/hw/rtl/libs
-incdir ${VX_HOME}/hw/rtl/interfaces
-incdir ${VX_HOME}/hw/rtl/core
-incdir ${VX_HOME}/hw/rtl/mem
-incdir ${VX_HOME}/hw/rtl/cache
-incdir ${VX_HOME}/hw/rtl/fpu
-incdir ${VX_HOME}/third_party/cvfpu/src/common_cells/include
-incdir ${VX_HOME}/third_party/cvfpu/src/common_cells/src
-incdir ${VX_HOME}/third_party/cvfpu/src

// ---- packages (dependency order) ----
${VX_HOME}/hw/rtl/VX_gpu_pkg.sv
${VX_HOME}/hw/rtl/fpu/VX_fpu_pkg.sv
${VX_HOME}/third_party/cvfpu/src/fpnew_pkg.sv
${VX_HOME}/third_party/cvfpu/src/common_cells/src/cf_math_pkg.sv
${VX_HOME}/third_party/cvfpu/src/fpu_div_sqrt_mvp/hdl/defs_div_sqrt_mvp.sv
${VX_HOME}/third_party/cvfpu/src/fpu_div_sqrt_mvp/hdl/control_mvp.sv
${VX_HOME}/third_party/cvfpu/src/fpu_div_sqrt_mvp/hdl/iteration_div_sqrt_mvp.sv
${VX_HOME}/third_party/cvfpu/src/fpu_div_sqrt_mvp/hdl/norm_div_sqrt_mvp.sv
${VX_HOME}/third_party/cvfpu/src/fpu_div_sqrt_mvp/hdl/nrbd_nrsc_mvp.sv
${VX_HOME}/third_party/cvfpu/src/fpu_div_sqrt_mvp/hdl/preprocess_mvp.sv
${VX_HOME}/third_party/cvfpu/src/fpu_div_sqrt_mvp/hdl/div_sqrt_top_mvp.sv
${VX_HOME}/third_party/cvfpu/src/fpu_div_sqrt_mvp/hdl/div_sqrt_mvp_wrapper.sv
${VX_HOME}/hw/rtl/VX_trace_pkg.sv

// ---- Xcelium-compat module overrides (explicit => shadow the -y copies) ----
${VX_HOME}/dv/shim/VX_cta_dispatch.sv
${VX_HOME}/dv/shim/VX_cache_bank.sv
${VX_HOME}/dv/shim/Vortex.sv
${VX_HOME}/dv/shim/VX_stream_xbar.sv
${VX_HOME}/dv/shim/VX_generic_arbiter.sv
${VX_HOME}/dv/shim/VX_onehot_encoder.sv

// ---- top-level shim (instantiates Vortex) ----
${VX_HOME}/sim/rtlsim/rtlsim_shim.sv

// ---- module library search (auto-resolve instantiated modules) ----
// dv/shim first: fixed copies of upstream modules that don't parse in xmvlog
-y ${VX_HOME}/dv/shim
-y ${VX_HOME}/hw/rtl
-y ${VX_HOME}/hw/rtl/libs
-y ${VX_HOME}/hw/rtl/interfaces
-y ${VX_HOME}/hw/rtl/core
-y ${VX_HOME}/hw/rtl/mem
-y ${VX_HOME}/hw/rtl/cache
-y ${VX_HOME}/hw/rtl/fpu
-y ${VX_HOME}/third_party/cvfpu/src
-y ${VX_HOME}/third_party/cvfpu/src/common_cells/src
+libext+.sv+.v
