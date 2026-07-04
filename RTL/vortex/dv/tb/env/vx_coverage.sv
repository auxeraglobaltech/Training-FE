// ============================================================
//  Functional coverage: memory traffic (bank / rw / byteen shape /
//  address region) and DCR accesses (boot regs, flush, rw).
// ============================================================
`ifndef VX_COVERAGE_SV
`define VX_COVERAGE_SV

class vx_coverage extends uvm_component;
  `uvm_component_utils(vx_coverage)

  uvm_analysis_imp #(vx_mem_txn, vx_coverage) mem_imp;

  vx_mem_txn cur_mem;
  vx_dcr_txn cur_dcr;

  covergroup cg_mem;
    option.per_instance = 1;
    cp_bank: coverpoint cur_mem.bank { bins b[] = {[0:`VX_CFG_PLATFORM_MEMORY_NUM_BANKS-1]}; }
    cp_rw:   coverpoint cur_mem.rw   { bins rd = {0}; bins wr = {1}; }
    cp_region: coverpoint cur_mem.byte_addr {
      bins io_exit  = {[64'h8340 : 64'h834F]};
      bins io_other = {[64'h0    : 64'h833F], [64'h8350 : 64'hFFFF]};
      bins code     = {[64'h8000_0000 : 64'h8001_FFFF]};
      bins data     = {[64'h8002_0000 : 64'h80FF_FFFF]};
      bins other    = default;
    }
    cp_byteen: coverpoint $countones(cur_mem.byteen) iff (cur_mem.rw) {
      bins word    = {4};
      bins partial = {[1:3], [5:63]};
      bins full    = {64};
    }
    x_bank_rw: cross cp_bank, cp_rw;
  endgroup

  covergroup cg_dcr;
    option.per_instance = 1;
    cp_addr: coverpoint cur_dcr.addr {
      bins flush       = {12'h000};
      bins startup     = {12'h010};
      bins args        = {[12'h014 : 12'h015]};
      bins block_dim   = {[12'h016 : 12'h018]};
      bins grid_dim    = {[12'h019 : 12'h01B]};
      bins lmem_blk    = {[12'h01C : 12'h01D]};
      bins warp_step   = {[12'h01E : 12'h020]};
      bins cluster_dim = {[12'h021 : 12'h023]};
      bins other       = default;
    }
    cp_rw: coverpoint cur_dcr.rw { bins rd = {0}; bins wr = {1}; }
  endgroup

  function new(string name, uvm_component parent);
    super.new(name, parent);
    mem_imp = new("mem_imp", this);
    cg_mem = new();
    cg_dcr = new();
  endfunction

  function void write(vx_mem_txn t);
    cur_mem = t;
    cg_mem.sample();
  endfunction

  // called via a dedicated imp-decl-free path: env connects the dcr monitor
  // to sample_dcr through a uvm_analysis_imp in a small adapter; to keep it
  // simple we expose a public method the env subscriber calls.
  function void sample_dcr(vx_dcr_txn t);
    cur_dcr = t;
    cg_dcr.sample();
  endfunction

  function void report_phase(uvm_phase phase);
    `uvm_info("COV", $sformatf("coverage: mem=%.1f%% dcr=%.1f%%",
              cg_mem.get_inst_coverage(), cg_dcr.get_inst_coverage()), UVM_LOW)
  endfunction
endclass

// tiny subscriber adapter: dcr monitor ap -> vx_coverage.sample_dcr
class vx_dcr_cov_sub extends uvm_subscriber #(vx_dcr_txn);
  `uvm_component_utils(vx_dcr_cov_sub)
  vx_coverage cov;
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction
  function void write(vx_dcr_txn t);
    if (cov != null) cov.sample_dcr(t);
  endfunction
endclass

`endif
