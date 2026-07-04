## ============================================================
##  Vortex GPGPU (single core) — DV simulation Makefile (Xcelium / xrun)
##
##  Run from dv/sim/ after: source ~/cshrc
##    make elab                          # Phase 1: compile+elaborate only
##    make vx_smoke                      # Phase 2: directed SV boot smoke
##    make sim TESTNAME=vx_base_test     # Phase 3+: UVM tests
##    make clean
##
##  DPI-free: SV_DPI is never defined -> VX_CFG_DPI_ENABLE never set.
##  FPU forced to FPNEW (pure-RTL FPnew from third_party/cvfpu).
## ============================================================

XRUN     = xrun
# vendored Vortex snapshot root (two levels up from dv/sim)
VX_HOME := $(shell cd ../.. && pwd)
# generated config headers (VX_config.vh / VX_types.vh) from `../configure`
VX_BUILD ?= $(VX_HOME)/build
ROOT    := $(VX_HOME)/dv
WAVES   ?= 0
SEED    ?= $(shell shuf -i 1-999999 -n 1 2>/dev/null || echo 1)

export VX_HOME
export VX_BUILD

COMMON_OPTS = -sv \
              -64bit \
              -timescale 1ns/1ps \
              -relax \
              -define SIMULATION \
              -define NDEBUG \
              -define VX_CFG_FPU_TYPE_FPNEW \
              -define VX_CFG_XLEN=32 \
              -define VX_CFG_XLEN_32 \
              -access +rwc

TESTNAME ?= vx_base_test
UVM_OPTS  = -uvm -uvmhome CDNS-1.2 +define+UVM_NO_DEPRECATED +define+UVM_OBJECT_MUST_HAVE_CONSTRUCTOR

COV ?= 0
COV_OPTS :=
ifeq ($(COV),1)
COV_OPTS := -coverage all -covoverwrite
endif

# HYBRID=1: compile the DPI-C golden model (dv/sw/ref/vx_ref.c) into the sim
# and enable the scoreboard's DPI cross-check (+REF=<kernel basename>).
# Note: only the TB imports DPI; the Vortex RTL build stays DPI-free
# (SV_DPI is never defined).
HYBRID ?= 0
HYBRID_OPTS :=
ifeq ($(HYBRID),1)
HYBRID_OPTS := -define VX_HYBRID $(ROOT)/sw/ref/vx_ref.c +REF=$(notdir $(KERNEL))
endif

.PHONY: elab vx_smoke sim cosim waves clean

# -------------------------------------------------------
# Phase 1 — compile + elaborate rtlsim_shim (the xrun portability gate).
#   No testbench: -elaborate stops after elaboration.
# -------------------------------------------------------
elab:
	@TS=$$(date +%Y%m%d_%H%M%S); RUN=$(ROOT)/sim/runs/elab_$${TS}; mkdir -p $${RUN}; \
	echo "=== Vortex 1-core elaboration (rtlsim_shim) ==="; echo "  run dir: $${RUN}"; \
	cd $(ROOT) && $(XRUN) $(COMMON_OPTS) -elaborate \
	  -f $(ROOT)/sim/filelist_vx.f \
	  -top rtlsim_shim \
	  -log $${RUN}/xrun.log; \
	echo ""; echo "--- result ($${RUN}/xrun.log) ---"; \
	grep -iE "\*E,|\*F,|\*W,(NON|SV|MC)|errors: [^0]|Elaboration" $${RUN}/xrun.log | tail -30 || true

# -------------------------------------------------------
# Phase 2 — directed SV smoke: preload program, boot DCRs, start, wait busy.
# -------------------------------------------------------
KERNEL ?= asm/nop
vx_smoke:
	@TS=$$(date +%Y%m%d_%H%M%S); RUN=$(ROOT)/sim/runs/smoke_$${TS}_seed$(SEED); mkdir -p $${RUN}; \
	echo "=== Vortex directed SV smoke (kernel: $(KERNEL)) ==="; echo "  run dir: $${RUN}"; \
	cd $(ROOT) && $(XRUN) $(COMMON_OPTS) \
	  -f $(ROOT)/sim/filelist_vx.f \
	  -f $(ROOT)/sim/filelist_smoke.f \
	  -top tb_top_vx_smoke \
	  +KERNEL=$(ROOT)/sw/tests/$(KERNEL).hex \
	  +ntb_random_seed=$(SEED) \
	  -log $${RUN}/xrun.log; \
	echo ""; echo "--- result ($${RUN}/xrun.log) ---"; \
	grep -iE "SMOKE:|\[OK\]|\[FAIL\]|EXITCODE|busy|\*E,|\*F," $${RUN}/xrun.log | tail -30 || true

# -------------------------------------------------------
# Phase 3+ — UVM: make sim TESTNAME=vx_base_test [KERNEL=c/vecadd] [COV=1] [WAVES=1]
# -------------------------------------------------------
sim:
	@TS=$$(date +%Y%m%d_%H%M%S); RUN=$(ROOT)/sim/runs/sim_$${TS}_$(TESTNAME)_seed$(SEED); mkdir -p $${RUN}; \
	echo "=== Vortex UVM: $(TESTNAME) ==="; echo "  run dir: $${RUN}"; \
	IN=""; \
	if [ "$(WAVES)" = "1" ]; then \
	  printf 'database -open waves -into %s/waves.shm -default\nprobe -create -shm -all -depth all -database waves\nrun\nexit\n' "$${RUN}" > $${RUN}/wave.tcl; \
	  IN="-input $${RUN}/wave.tcl"; \
	  echo "  waves: $${RUN}/waves.shm"; \
	fi; \
	cd $(ROOT) && $(XRUN) $(COMMON_OPTS) $(UVM_OPTS) $(COV_OPTS) $(HYBRID_OPTS) \
	  -f $(ROOT)/sim/filelist_vx.f \
	  -f $(ROOT)/sim/filelist_uvm.f \
	  -top tb_top_vx_uvm \
	  +UVM_TESTNAME=$(TESTNAME) \
	  +KERNEL=$(ROOT)/sw/tests/$(KERNEL).hex \
	  $$( [ -f $(ROOT)/sw/tests/$(KERNEL).expected.hex ] && echo +EXPECTED=$(ROOT)/sw/tests/$(KERNEL).expected.hex ) \
	  +ntb_random_seed=$(SEED) \
	  $${IN} \
	  -log $${RUN}/xrun.log; \
	echo ""; echo "--- result ($${RUN}/xrun.log) ---"; \
	grep -iE "RESULT|SCOREBOARD|UVM_ERROR :|UVM_FATAL :|EXITCODE|\*E,|\*F," $${RUN}/xrun.log | tail -20 || true

# -------------------------------------------------------
# Open newest waves.shm in SimVision with the design snapshot.
# -------------------------------------------------------
WAVE_RUN ?= $(shell ls -dt $(ROOT)/sim/runs/sim_*/ 2>/dev/null | head -1)
waves:
	@CDS=$$(find $(ROOT)/xcelium.d -name cds.lib -path '*run.*.d*' 2>/dev/null | head -1); \
	if [ -z "$(WAVE_RUN)" ] || [ ! -e "$(WAVE_RUN)/waves.shm" ]; then \
	  echo "no waves.shm found in '$(WAVE_RUN)'. Run:  make sim TESTNAME=<t> WAVES=1"; exit 1; fi; \
	echo "opening $(WAVE_RUN)/waves.shm  (snapshot worklib.tb_top_vx_uvm:sv)"; \
	cd $(ROOT) && simvision -64 -cdslib $${CDS} -snapshot worklib.tb_top_vx_uvm:sv $(WAVE_RUN)/waves.shm &

# -------------------------------------------------------
# simx co-sim: run the same kernel ELF on the cycle-approximate C++ golden
# simulator. PASS = simx exits 0 (same boot/DCR/exit-code contract).
#   make cosim KERNEL=c/vecadd
# -------------------------------------------------------
SIMX := $(VX_HOME)/build/sim/simx/simx
cosim:
	@if [ ! -x $(SIMX) ]; then echo "simx not built: make -C $(VX_HOME)/build/sim/simx"; exit 1; fi; \
	echo "=== simx co-sim (kernel: $(KERNEL)) ==="; \
	$(SIMX) $(ROOT)/sw/tests/$(KERNEL).elf && echo "COSIM: [OK] simx exit 0" \
	  || (echo "COSIM: [FAIL] simx non-zero exit"; exit 1)

# -------------------------------------------------------
clean:
	rm -rf $(ROOT)/sim/runs $(ROOT)/xcelium.d $(ROOT)/.simvision \
	       $(ROOT)/waves.shm $(ROOT)/*.log $(ROOT)/*.history $(ROOT)/sim/*.log
