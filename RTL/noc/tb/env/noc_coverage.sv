// ============================================================================
//  noc_coverage.sv  —  functional coverage (the verification surface)
// ----------------------------------------------------------------------------
//  THE coverpoint is the routing matrix (master x target x direction).  Plus
//  QoS bins and a master x qos cross so dynamic-priority arbitration coverage
//  can be tracked.  Sampled on every completed master transaction.
// ============================================================================
`uvm_analysis_imp_decl(_cm0)
`uvm_analysis_imp_decl(_cm1)

class noc_coverage extends uvm_component;
  `uvm_component_utils(noc_coverage)

  uvm_analysis_imp_cm0 #(axi_seq_item, noc_coverage) cm0_imp;
  uvm_analysis_imp_cm1 #(axi_seq_item, noc_coverage) cm1_imp;

  // sampled fields
  bit                c_master;   // 0 = M0, 1 = M1
  noc_pkg::target_e  c_tgt;
  bit                c_wr;
  bit [3:0]          c_qos;

  covergroup noc_cg;
    option.per_instance = 1;
    master_cp : coverpoint c_master { bins m0 = {1'b0}; bins m1 = {1'b1}; }
    target_cp : coverpoint c_tgt {
      bins s0={noc_pkg::TGT_S0}; bins s1={noc_pkg::TGT_S1};
      bins p0={noc_pkg::TGT_P0}; bins p1={noc_pkg::TGT_P1};
      bins decerr={noc_pkg::TGT_NONE};
    }
    dir_cp : coverpoint c_wr { bins rd={1'b0}; bins wr={1'b1}; }
    qos_cp : coverpoint c_qos { bins lo={[0:7]}; bins hi={[8:15]}; }

    route_x : cross master_cp, target_cp, dir_cp;   // every master->target, R & W
    qos_x   : cross master_cp, qos_cp;              // each master at lo/hi priority
  endgroup

  function new(string name, uvm_component parent);
    super.new(name, parent);
    noc_cg = new();
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    cm0_imp = new("cm0_imp", this);
    cm1_imp = new("cm1_imp", this);
  endfunction

  function void write_cm0(axi_seq_item t); sample_tr(1'b0, t); endfunction
  function void write_cm1(axi_seq_item t); sample_tr(1'b1, t); endfunction

  function void sample_tr(bit m, axi_seq_item t);
    c_master = m;
    c_tgt    = noc_pkg::decode(t.addr);
    c_wr     = t.is_write;
    c_qos    = t.qos;
    noc_cg.sample();
  endfunction

  function void report_phase(uvm_phase phase);
    `uvm_info("COV", $sformatf("Functional coverage = %.1f%% (route_x=%.1f%%)",
              noc_cg.get_inst_coverage(), noc_cg.route_x.get_inst_coverage()), UVM_LOW)
  endfunction

endclass : noc_coverage
