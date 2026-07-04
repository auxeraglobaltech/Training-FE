## ============================================================
##  UberDDR3 — DV simulation Makefile (Cadence Xcelium / xrun)
##
##  Run from dv/sim/ after: source ~/cshrc
##    make wb           # Phase 0: Wishbone Micron BIST bring-up (no UVM)
##    make axi_smoke    # Phase 1: directed AXI self-check (no UVM)   [added later]
##    make sim TESTNAME=ddr_sanity_test   # Phase 3+: UVM tests       [added later]
##    make clean
##
##  Vendor-free: SIM_MODEL selects the bundled behavioral PHY primitive
##  models, so no Xilinx unisim / glbl libraries are needed.
## ============================================================

XRUN      = xrun
# repo root of the vendored snapshot (two levels up from dv/sim)
ROOT     := $(shell cd ../.. && pwd)
WAVES    ?= 0
SEED     ?= $(shell shuf -i 1-999999 -n 1 2>/dev/null || echo 1)

COMMON_OPTS = -sv \
              -timescale 1ns/1ps \
              -relax \
              -define SIM_MODEL \
              -define NO_TEST_MODEL \
              -access +rwc

TESTNAME ?= ddr_sanity_test
UVM_OPTS  = -uvm -uvmhome CDNS-1.2 +define+UVM_NO_DEPRECATED +define+UVM_OBJECT_MUST_HAVE_CONSTRUCTOR

# Coverage: COV=1 -> enable functional + code coverage
COV ?= 0
COV_OPTS :=
ifeq ($(COV),1)
COV_OPTS := -coverage all -covoverwrite
endif

.PHONY: wb wb_smoke axi_smoke sim waves clean

# -------------------------------------------------------
# Phase 0 — Wishbone bring-up: existing Micron testbench in Xcelium.
#   Expect: calibration completes, built-in BIST reports PASS, $finish.
# -------------------------------------------------------
wb:
	@TS=$$(date +%Y%m%d_%H%M%S); RUN=$(ROOT)/dv/sim/runs/wb_$${TS}_seed$(SEED); mkdir -p $${RUN}; \
	echo "=== UberDDR3 Wishbone bring-up ==="; echo "  run dir: $${RUN}"; \
	WV=""; if [ "$(WAVES)" = "1" ]; then WV="+DUMP_WAVES"; fi; \
	cd $(ROOT) && $(XRUN) $(COMMON_OPTS) \
	  -f $(ROOT)/dv/sim/filelist_wb.f \
	  -top ddr3_dimm_micron_sim \
	  -input $(ROOT)/dv/sim/run_exit.tcl \
	  +ntb_random_seed=$(SEED) \
	  -log $${RUN}/xrun.log $${WV}; \
	echo ""; echo "--- result ($${RUN}/xrun.log) ---"; \
	grep -iE "SUMMARY|Number of (Writes|Reads|Success|Fails|Injected)|correct_read|wrong_read|calib|\*E,|\*F," $${RUN}/xrun.log | tail -25 || true

# -------------------------------------------------------
# Directed Wishbone smoke (no UVM): native WB interface, wait calib, W/R self-check.
# -------------------------------------------------------
wb_smoke:
	@TS=$$(date +%Y%m%d_%H%M%S); RUN=$(ROOT)/dv/sim/runs/wbsmoke_$${TS}_seed$(SEED); mkdir -p $${RUN}; \
	echo "=== UberDDR3 native-Wishbone directed smoke ==="; echo "  run dir: $${RUN}"; \
	cd $(ROOT) && $(XRUN) $(COMMON_OPTS) \
	  -f $(ROOT)/dv/sim/filelist_wb_smoke.f \
	  -top tb_top_wb \
	  -input $(ROOT)/dv/sim/run_exit.tcl \
	  +ntb_random_seed=$(SEED) \
	  -log $${RUN}/xrun.log; \
	echo ""; echo "--- result ($${RUN}/xrun.log) ---"; \
	grep -iE "SMOKE:|\[OK\]|\[FAIL\]|\[STALL\]|calibration|\*E,|\*F," $${RUN}/xrun.log | tail -30 || true

# -------------------------------------------------------
# Phase 1 — directed AXI smoke (no UVM): wait calibration, W/R self-check.
# -------------------------------------------------------
axi_smoke:
	@TS=$$(date +%Y%m%d_%H%M%S); RUN=$(ROOT)/dv/sim/runs/axi_$${TS}_seed$(SEED); mkdir -p $${RUN}; \
	echo "=== UberDDR3 AXI directed smoke ==="; echo "  run dir: $${RUN}"; \
	WV=""; if [ "$(WAVES)" = "1" ]; then WV="+DUMP_WAVES"; fi; \
	cd $(ROOT) && $(XRUN) $(COMMON_OPTS) \
	  -f $(ROOT)/dv/sim/filelist_axi.f \
	  -top tb_top_axi \
	  -input $(ROOT)/dv/sim/run_exit.tcl \
	  +ntb_random_seed=$(SEED) \
	  -log $${RUN}/xrun.log $${WV}; \
	echo ""; echo "--- result ($${RUN}/xrun.log) ---"; \
	grep -iE "SMOKE:|\[OK\]|\[FAIL\]|\[STALL\]|\[WB\]|\[WRBR\]|\[PRB\]|AW\+W|B received|R received|calibration|\*E,|\*F," $${RUN}/xrun.log | tail -60 || true

# -------------------------------------------------------
# UVM simulation (Wishbone env): make sim TESTNAME=ddr_sanity_test [COV=1] [WAVES=1]
#   WAVES=1 dumps a full-hierarchy SHM database into the run dir (waves.shm);
#   open it with:  simvision <run_dir>/waves.shm
# -------------------------------------------------------
sim:
	@TS=$$(date +%Y%m%d_%H%M%S); RUN=$(ROOT)/dv/sim/runs/sim_$${TS}_$(TESTNAME)_seed$(SEED); mkdir -p $${RUN}; \
	echo "=== UberDDR3 Wishbone UVM: $(TESTNAME) ==="; echo "  run dir: $${RUN}"; \
	IN=""; \
	if [ "$(WAVES)" = "1" ]; then \
	  printf 'database -open waves -into %s/waves.shm -default\nprobe -create -shm -all -depth all -database waves\nrun\nexit\n' "$${RUN}" > $${RUN}/wave.tcl; \
	  IN="-input $${RUN}/wave.tcl"; \
	  echo "  waves: $${RUN}/waves.shm"; \
	fi; \
	cd $(ROOT) && $(XRUN) $(COMMON_OPTS) $(UVM_OPTS) $(COV_OPTS) \
	  -f $(ROOT)/dv/sim/filelist_uvm.f \
	  -top tb_top_wb_uvm \
	  +UVM_TESTNAME=$(TESTNAME) \
	  +ntb_random_seed=$(SEED) \
	  $${IN} \
	  -log $${RUN}/xrun.log; \
	echo ""; echo "--- result ($${RUN}/xrun.log) ---"; \
	grep -iE "RESULT|SCOREBOARD|UVM_ERROR :|UVM_FATAL :|calibration|\*E,|\*F," $${RUN}/xrun.log | tail -20 || true

# -------------------------------------------------------
# Open a waveform DB in SimVision WITH the design snapshot, so the Source and
# Schematic browsers work (avoids the PPESNAP "Unable to start the Post
# Processing Environment" error) and instance pins show real input/output
# direction. Defaults to the newest run; override with WAVE_RUN=<run dir>.
#   make waves
#   make waves WAVE_RUN=dv/sim/runs/sim_..._ddr_walk_test_seedNNN
# -------------------------------------------------------
WAVE_RUN ?= $(shell ls -dt $(ROOT)/dv/sim/runs/sim_*/ 2>/dev/null | head -1)
waves:
	@CDS=$$(find $(ROOT)/xcelium.d -name cds.lib -path '*run.*.d*' 2>/dev/null | head -1); \
	if [ -z "$(WAVE_RUN)" ] || [ ! -e "$(WAVE_RUN)/waves.shm" ]; then \
	  echo "no waves.shm found in '$(WAVE_RUN)'. Run:  make sim TESTNAME=<t> WAVES=1"; exit 1; fi; \
	echo "opening $(WAVE_RUN)/waves.shm  (snapshot worklib.tb_top_wb_uvm:sv)"; \
	cd $(ROOT) && simvision -64 -cdslib $${CDS} -snapshot worklib.tb_top_wb_uvm:sv $(WAVE_RUN)/waves.shm &

# -------------------------------------------------------
clean:
	rm -rf $(ROOT)/dv/sim/runs $(ROOT)/xcelium.d $(ROOT)/.simvision \
	       $(ROOT)/waves.shm $(ROOT)/*.log $(ROOT)/*.history $(ROOT)/dv/sim/*.log
