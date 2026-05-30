XRUN      = xrun
REPO_ROOT = ..
TEST      = hello_world
XRUN_OPTS = -sv \
            -uvm -uvmhome CDNS-1.2 \
            -access +rwc \
            -timescale 1ns/1ps \
            +define+UVM_NO_DEPRECATED \
            +define+UVM_OBJECT_MUST_HAVE_CONSTRUCTOR \
            -top tb_top \
            -log sim/xrun.log

.PHONY: sw sim waves clean

sw:
	cd $(REPO_ROOT) && make -f sw/Makefile TEST=$(TEST)

sim: sw
	cd $(REPO_ROOT) && $(XRUN) $(XRUN_OPTS) -f filelist.f \
	  +UVM_TESTNAME=ibex_base_test
	@grep -E "PASSED|FAILED|UVM_ERROR|UVM_FATAL" \
	  $(REPO_ROOT)/sim/xrun.log | tail -5

waves: sw
	cd $(REPO_ROOT) && $(XRUN) $(XRUN_OPTS) -f filelist.f \
	  +UVM_TESTNAME=ibex_base_test \
	  -input sim/run.tcl

clean:
	rm -f $(REPO_ROOT)/sim/*.elf $(REPO_ROOT)/sim/*.vmem \
	      $(REPO_ROOT)/sim/xrun.log
	rm -rf $(REPO_ROOT)/xcelium.d $(REPO_ROOT)/.simvision \
	       $(REPO_ROOT)/waves.shm
