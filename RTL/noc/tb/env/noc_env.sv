// ============================================================================
//  noc_env.sv  —  the NoC UVM environment
// ----------------------------------------------------------------------------
//  2 active master agents, 2 reactive AXI slave responders (+ arrival monitors),
//  2 reactive APB responders (+ monitors), routing-aware scoreboard, coverage,
//  and a virtual sequencer.  Fetches the six DUT vifs (published by tb_top) and
//  distributes them to the components, then wires every monitor into the
//  scoreboard (tagged per port) and the master monitors into coverage.
// ============================================================================
class noc_env extends uvm_env;
  `uvm_component_utils(noc_env)

  typedef virtual axi_if #(noc_pkg::ADDR_WIDTH, noc_pkg::DATA_WIDTH,
                           noc_pkg::STRB_WIDTH, noc_pkg::ID_WIDTH)     axi_m_vif_t;
  typedef virtual axi_if #(noc_pkg::ADDR_WIDTH, noc_pkg::DATA_WIDTH,
                           noc_pkg::STRB_WIDTH, noc_pkg::SLV_ID_WIDTH) axi_s_vif_t;
  typedef virtual apb_if #(noc_pkg::ADDR_WIDTH, noc_pkg::DATA_WIDTH,
                           noc_pkg::STRB_WIDTH)                        apb_vif_t;

  axi_master_agent     m0_agent, m1_agent;
  axi_slave_responder  s0_resp,  s1_resp;
  axi_req_monitor      s0_mon,   s1_mon;
  apb_slave_responder  p0_resp,  p1_resp;
  apb_monitor          p0_mon,   p1_mon;
  noc_scoreboard       sb;
  noc_coverage         cov;
  noc_vseqr            vseqr;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    axi_m_vif_t m0_vif, m1_vif;
    axi_s_vif_t s0_vif, s1_vif;
    apb_vif_t   p0_vif, p1_vif;
    super.build_phase(phase);

    if (!uvm_config_db#(axi_m_vif_t)::get(this,"","m0_vif",m0_vif)) `uvm_fatal("ENV","no m0_vif")
    if (!uvm_config_db#(axi_m_vif_t)::get(this,"","m1_vif",m1_vif)) `uvm_fatal("ENV","no m1_vif")
    if (!uvm_config_db#(axi_s_vif_t)::get(this,"","s0_vif",s0_vif)) `uvm_fatal("ENV","no s0_vif")
    if (!uvm_config_db#(axi_s_vif_t)::get(this,"","s1_vif",s1_vif)) `uvm_fatal("ENV","no s1_vif")
    if (!uvm_config_db#(apb_vif_t)::get(this,"","p0_vif",p0_vif))   `uvm_fatal("ENV","no p0_vif")
    if (!uvm_config_db#(apb_vif_t)::get(this,"","p1_vif",p1_vif))   `uvm_fatal("ENV","no p1_vif")

    // distribute vifs to children
    uvm_config_db#(axi_m_vif_t)::set(this,"m0_agent*","vif",m0_vif);
    uvm_config_db#(axi_m_vif_t)::set(this,"m1_agent*","vif",m1_vif);
    uvm_config_db#(axi_s_vif_t)::set(this,"s0_resp*","vif",s0_vif);
    uvm_config_db#(axi_s_vif_t)::set(this,"s0_mon*","vif",s0_vif);
    uvm_config_db#(axi_s_vif_t)::set(this,"s1_resp*","vif",s1_vif);
    uvm_config_db#(axi_s_vif_t)::set(this,"s1_mon*","vif",s1_vif);
    uvm_config_db#(apb_vif_t)::set(this,"p0_resp*","vif",p0_vif);
    uvm_config_db#(apb_vif_t)::set(this,"p0_mon*","vif",p0_vif);
    uvm_config_db#(apb_vif_t)::set(this,"p1_resp*","vif",p1_vif);
    uvm_config_db#(apb_vif_t)::set(this,"p1_mon*","vif",p1_vif);

    m0_agent = axi_master_agent::type_id::create("m0_agent", this);
    m1_agent = axi_master_agent::type_id::create("m1_agent", this);
    s0_resp  = axi_slave_responder::type_id::create("s0_resp", this);
    s1_resp  = axi_slave_responder::type_id::create("s1_resp", this);
    s0_mon   = axi_req_monitor::type_id::create("s0_mon", this);
    s1_mon   = axi_req_monitor::type_id::create("s1_mon", this);
    p0_resp  = apb_slave_responder::type_id::create("p0_resp", this);
    p1_resp  = apb_slave_responder::type_id::create("p1_resp", this);
    p0_mon   = apb_monitor::type_id::create("p0_mon", this);
    p1_mon   = apb_monitor::type_id::create("p1_mon", this);
    sb       = noc_scoreboard::type_id::create("sb", this);
    cov      = noc_coverage::type_id::create("cov", this);
    vseqr    = noc_vseqr::type_id::create("vseqr", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    // master monitors -> scoreboard + coverage
    m0_agent.mon.ap.connect(sb.m0_imp);
    m1_agent.mon.ap.connect(sb.m1_imp);
    m0_agent.mon.ap.connect(cov.cm0_imp);
    m1_agent.mon.ap.connect(cov.cm1_imp);
    // slave arrival monitors -> scoreboard (routing)
    s0_mon.ap.connect(sb.s0_imp);
    s1_mon.ap.connect(sb.s1_imp);
    p0_mon.ap.connect(sb.p0_imp);
    p1_mon.ap.connect(sb.p1_imp);
    // virtual sequencer handles
    vseqr.m0_seqr = m0_agent.seqr;
    vseqr.m1_seqr = m1_agent.seqr;
  endfunction

endclass : noc_env
