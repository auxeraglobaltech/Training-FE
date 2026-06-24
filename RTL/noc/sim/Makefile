## ============================================================
##  2x2x2 NoC — Xcelium Simulation Makefile
##
##  Run from the sim/ directory:
##    make elab                              # compile + elaborate only
##    make sim                               # run base test
##    make sim TESTNAME=noc_sanity_test      # pick a UVM test
##    make sim TESTNAME=noc_rr_arb_test WAVES=1 SEED=42
##    make sim TESTNAME=noc_decode_test BUG=DECERR_OMIT   # inject a bug
##    make clean
##
##  Tooling: source ~/cshrc first so `xrun` (Xcelium 2503) is on PATH.
## ============================================================

XRUN      = xrun
REPO_ABS := $(shell cd .. && pwd)
TESTNAME ?= noc_base_test
WAVES    ?= 0
COV      ?= 0
SEED     ?= $(shell shuf -i 1-999999 -n 1 2>/dev/null || echo 1)
BUG      ?=

# Coverage: COV=1 -> enable functional + code coverage collection
COV_OPTS :=
ifeq ($(COV),1)
COV_OPTS := -coverage all -covoverwrite
endif

# Optional bug injection: BUG=DECERR_OMIT -> +define+NOC_BUG_DECERR_OMIT
BUG_DEF :=
ifneq ($(BUG),)
BUG_DEF := +define+NOC_BUG_$(BUG)
endif

INCDIRS   = +incdir+$(REPO_ABS)
XRUN_OPTS = -sv \
            -uvm -uvmhome CDNS-1.2 \
            -access +rwc \
            -timescale 1ns/1ps \
            +define+UVM_NO_DEPRECATED \
            +define+UVM_OBJECT_MUST_HAVE_CONSTRUCTOR \
            $(BUG_DEF) \
            $(COV_OPTS) \
            $(INCDIRS) \
            -top tb_top

.PHONY: elab sim smoke clean

# -------------------------------------------------------
# Elaborate only — fast syntax/elaboration check
# -------------------------------------------------------
elab:
	cd $(REPO_ABS) && $(XRUN) -elaborate $(XRUN_OPTS) -f sim/filelist.f -log sim/elab.log
	@echo ""
	@echo "--- Elaboration result (errors, if any) ---"
	@grep -iE "error|\*[EF]," $(REPO_ABS)/sim/elab.log | tail -20 || true
	@echo "(no lines above means a clean elaboration)"

# -------------------------------------------------------
# Simulation run — creates runs/run_<ts>_seed<N>/
# -------------------------------------------------------
sim:
	@TIMESTAMP=$$(date +%Y%m%d_%H%M%S); \
	RUN_DIR=$(REPO_ABS)/sim/runs/run_$${TIMESTAMP}_seed$(SEED); \
	mkdir -p $${RUN_DIR}; \
	echo ""; \
	echo "============================================"; \
	echo "  Run dir  : $${RUN_DIR}"; \
	echo "  Test     : $(TESTNAME)"; \
	echo "  Seed     : $(SEED)"; \
	echo "  Waves    : $(WAVES)"; \
	echo "  Bug      : $(BUG)"; \
	echo "============================================"; \
	echo ""; \
	WAVE_OPTS=""; \
	if [ "$(WAVES)" = "1" ]; then WAVE_OPTS="+DUMP_WAVES"; fi; \
	cd $(REPO_ABS) && $(XRUN) $(XRUN_OPTS) \
	  -f sim/filelist.f \
	  +UVM_TESTNAME=$(TESTNAME) \
	  +ntb_random_seed=$(SEED) \
	  -log $${RUN_DIR}/xrun.log \
	  $${WAVE_OPTS}; \
	SIM_RC=$$?; \
	if [ "$(WAVES)" = "1" ] && [ -e $(REPO_ABS)/waves.shm ]; then \
	  mv $(REPO_ABS)/waves.shm $${RUN_DIR}/waves.shm; \
	fi; \
	echo ""; \
	echo "--- Results ($${RUN_DIR}/xrun.log) ---"; \
	grep -E "PASSED|FAILED|UVM_ERROR|UVM_FATAL|UVM_WARNING" $${RUN_DIR}/xrun.log | tail -15 || true; \
	echo ""; \
	exit $${SIM_RC}

# -------------------------------------------------------
# Directed datapath smoke (non-UVM, behavioral BFMs)
# -------------------------------------------------------
smoke:
	cd $(REPO_ABS) && $(XRUN) -sv -access +rwc -timescale 1ns/1ps $(BUG_DEF) $(INCDIRS) \
	  -top smoke_tb -f sim/filelist_smoke.f -log sim/smoke.log
	@echo ""
	@echo "--- Smoke result ---"
	@grep -E "SMOKE:|  \[|\*E,|\*F," $(REPO_ABS)/sim/smoke.log | tail -40 || true

# -------------------------------------------------------
# Clean build + run artefacts
# -------------------------------------------------------
clean:
	rm -rf $(REPO_ABS)/xcelium.d \
	       $(REPO_ABS)/.simvision \
	       $(REPO_ABS)/waves.shm \
	       $(REPO_ABS)/sim/runs \
	       $(REPO_ABS)/sim/elab.log \
	       $(REPO_ABS)/*.log \
	       $(REPO_ABS)/*.history
