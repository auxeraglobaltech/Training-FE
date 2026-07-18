SIM      = xrun
 
RTL_DIR  = ./rtl
TB_DIR   = ./tb
SIM_DIR  = ./sim
 
FILELIST = ./sim/flist.f
 
TEST ?= test
 
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
	-input wave.tcl \
	-svseed $(SEED) \
	-l $(OUT_DIR)/run.log
 
incr_aligned:
	$(MAKE) run TEST=axi_incr_aligned_test 
incr_unaligned:
	$(MAKE) run TEST=axi_incr_unaligned_test 
fixed_aligned:
	$(MAKE) run TEST=axi_fixed_aligned_test 
wrap_aligned:
	$(MAKE) run TEST=axi_wrap_aligned_test
outstanding:
	$(MAKE) run TEST=axi_outstanding_wr_rd_test
ooo:
	$(MAKE) run TEST=axi_ooo_wr_rd_test



test:
	$(MAKE) run TEST=test
 
 
regression:
	$(MAKE) incr_aligned
	$(MAKE) incr_unaligned
	$(MAKE) fixed_aligned
	$(MAKE) wrap_aligned
	$(MAKE) outstanding
	$(MAKE) ooo
	$(MAKE) test 

reg_random:
 
	$(MAKE) regression SEED=random
 
reg_seed:
 
	$(MAKE) regression SEED=20
 
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
help:
	@echo ""
	@echo "================ AXI UVM Makefile ================="
	@echo ""
	@echo "make incr_aligned"
	@echo "make incr_unaligned"
	@echo "make fixed_aligned"
	@echo "make wrap_aligned"
	@echo "make outstanding"
	@echo "make ooo"
	@echo "make test" 
	@echo ""
	@echo "make regression"
	@echo "make reg_random"
	@echo "make reg_seed"
	@echo ""
	@echo "make wave TEST=axi_incr_aligned_test"
	@echo "make wave TEST=axi_incr_unaligned_test"
	@echo "make wave TEST=axi_fixed_aligned_test"
	@echo "make wave TEST=axi_wrap_aligned_test"
	@echo "make wave TEST=axi_outstanding_wr_rd_test"
	@echo "make wave TEST=axi_ooo_wr_rd_test"
	@echo "make wave TEST=test"

	@echo "make log TEST=axi_incr_aligned_test"
	@echo "make log TEST=axi_incr_unaligned_test"
	@echo "make log TEST=axi_fixed_aligned_test"
	@echo "make log TEST=axi_wrap_aligned_test"
	@echo "make log TEST=axi_outstanding_wr_rd_test"
	@echo "make log TEST=axi_ooo_wr_rd_test"
	@echo "make log TEST=test"
	@echo ""
	@echo "make clean"
	@echo "=================================================="
