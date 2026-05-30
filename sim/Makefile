## ============================================================
##  Ibex UVM Simulation Makefile
##
##  Usage (run from sim/ directory):
##    make sim                    # basic run, no waves
##    make sim WAVES=1            # run + dump waveforms
##    make sim SEED=12345         # fixed seed
##    make sim WAVES=1 SEED=42   # fixed seed + waves
##    make sw                     # SW build only
##    make clean                  # remove build + run artefacts
## ============================================================

XRUN      = xrun
REPO_ABS := $(shell cd .. && pwd)
TEST      = hello_world
TEST_NAME = ibex_base_test
WAVES    ?= 0
SEED     ?= $(shell shuf -i 1-999999 -n 1 2>/dev/null || echo 1)

XRUN_OPTS = -sv \
            -uvm -uvmhome CDNS-1.2 \
            -access +rwc \
            -timescale 1ns/1ps \
            +define+UVM_NO_DEPRECATED \
            +define+UVM_OBJECT_MUST_HAVE_CONSTRUCTOR \
            -top tb_top

.PHONY: sw sim clean

# -------------------------------------------------------
# SW build  (ELF + vmem + dis)
# -------------------------------------------------------
sw:
	cd $(REPO_ABS) && make -f sw/Makefile TEST=$(TEST)

# -------------------------------------------------------
# Simulation run
#   - Creates runs/run_YYYYMMDD_HHMMSS_seed<N>/
#   - Copies log, vmem, dis into that folder
#   - Copies waves.shm into that folder if WAVES=1
# -------------------------------------------------------
sim: sw
	@TIMESTAMP=$$(date +%Y%m%d_%H%M%S); \
	RUN_DIR=$(REPO_ABS)/runs/run_$${TIMESTAMP}_seed$(SEED); \
	mkdir -p $${RUN_DIR}; \
	echo ""; \
	echo "============================================"; \
	echo "  Run dir : $${RUN_DIR}"; \
	echo "  Test    : $(TEST_NAME)"; \
	echo "  Seed    : $(SEED)"; \
	echo "  Waves   : $(WAVES)"; \
	echo "============================================"; \
	echo ""; \
	WAVE_OPTS=""; \
	if [ "$(WAVES)" = "1" ]; then \
	  WAVE_OPTS="+DUMP_WAVES +SHM_PATH=$${RUN_DIR}/waves.shm"; \
	fi; \
	cd $(REPO_ABS) && $(XRUN) $(XRUN_OPTS) \
	  -f filelist.f \
	  +UVM_TESTNAME=$(TEST_NAME) \
	  +ntb_random_seed=$(SEED) \
	  -log $${RUN_DIR}/xrun.log \
	  $${WAVE_OPTS}; \
	SIM_RC=$$?; \
	echo ""; \
	echo "--- Copying artefacts to $${RUN_DIR} ---"; \
	cp -f $(REPO_ABS)/sim/$(TEST).vmem $${RUN_DIR}/ 2>/dev/null && echo "  vmem: $(TEST).vmem" || true; \
	cp -f $(REPO_ABS)/sim/$(TEST).dis  $${RUN_DIR}/ 2>/dev/null && echo "  dis : $(TEST).dis"  || true; \
	echo ""; \
	echo "--- Results ---"; \
	grep -E "PASSED|FAILED|UVM_ERROR|UVM_FATAL" $${RUN_DIR}/xrun.log | tail -10 || true; \
	echo ""; \
	echo "Artefacts saved to: $${RUN_DIR}"; \
	exit $${SIM_RC}

# -------------------------------------------------------
# Clean build artefacts and all run directories
# -------------------------------------------------------
clean:
	rm -f $(REPO_ABS)/sim/*.elf \
	      $(REPO_ABS)/sim/*.vmem \
	      $(REPO_ABS)/sim/*.dis
	rm -rf $(REPO_ABS)/xcelium.d \
	       $(REPO_ABS)/.simvision \
	       $(REPO_ABS)/waves.shm \
	       $(REPO_ABS)/runs
