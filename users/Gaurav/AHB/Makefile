SIM      = xrun

RTL_DIR  = ./rtl
TB_DIR   = ./tb
SIM_DIR  = ./sim

FILELIST = flist.f

TEST ?= ahb_write_test

SEED ?= random

OUT_DIR = $(SIM_DIR)/$(TEST)

XRUN_OPTIONS = \
-access +rwc \
-uvm \
-timescale 1ns/1ps

UVM_OPTIONS = \
+UVM_TESTNAME=$(TEST) \
+UVM_VERBOSITY=UVM_MEDIUM \
+UVM_NO_RELNOTES

run:
	@mkdir -p $(OUT_DIR)

	@echo ""
	@echo "========================================="
	@echo "Running Test : $(TEST)"
	@echo "Seed         : $(SEED)"
	@echo "Output Dir   : $(OUT_DIR)"
	@echo "========================================="
	@echo ""

	TEST=$(TEST) \
	OUT_DIR=$(OUT_DIR) \
	$(SIM) \
	$(XRUN_OPTIONS) \
	-f $(FILELIST) \
	$(UVM_OPTIONS) \
	-input waves.tcl \
	-svseed $(SEED) \
	-l $(OUT_DIR)/run.log

reset:
	$(MAKE) run TEST=ahb_reset_test

write:
	$(MAKE) run TEST=ahb_write_test

read:
	$(MAKE) run TEST=ahb_read_test

idle:
	$(MAKE) run TEST=ahb_idle_test

random:
	$(MAKE) run TEST=ahb_random_test

b2b_write:
	$(MAKE) run TEST=ahb_back_to_back_write_test

b2b_read:
	$(MAKE) run TEST=ahb_back_to_back_read_test

mixed:
	$(MAKE) run TEST=ahb_mixed_rw_test

wr_rd:
	$(MAKE) run TEST=ahb_write_read_test

wrap4:
	$(MAKE) run TEST=ahb_wrap4_write_test

regression:

	$(MAKE) reset
	$(MAKE) write
	$(MAKE) read
	$(MAKE) idle
	$(MAKE) random
	$(MAKE) b2b_write
	$(MAKE) b2b_read
	$(MAKE) mixed
	$(MAKE) wr_rd
	$(MAKE) wrap4


reg_random:

	$(MAKE) regression SEED=random

reg_seed:

	$(MAKE) regression SEED=10

wave:

	simvision $(OUT_DIR)/waves.shm &

log:

	less $(OUT_DIR)/run.log

clean:

	rm -rf INCA_libs
	rm -rf xcelium.d
	rm -rf *.history
	rm -rf *.log
	rm -rf *.jou
	rm -rf *.diag
	rm -rf *.shm
	rm -rf *.vcd
	rm -rf *.trn
	rm -rf sim/*

help:

	@echo ""
	@echo "================ AHB UVM Makefile ================="
	@echo ""
	@echo "make write"
	@echo "make read"
	@echo "make reset"
	@echo "make idle"
	@echo "make random"
	@echo "make b2b_write"
	@echo "make b2b_read"
	@echo "make mixed"
	@echo "make wr_rd"
	@echo "make wrap4"
	@echo ""
	@echo "make regression"
	@echo "make reg_random"
	@echo "make reg_seed"
	@echo ""
	@echo "make wave TEST=ahb_write_test"
	@echo "make wave TEST=ahb_read_test"
	@echo "make log TEST=ahb_write_test"
	@echo ""
	@echo "make clean"
	@echo "=================================================="
