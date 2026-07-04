// ============================================================
//  vx_env: per-bank mem agents (reactive) + dcr agent + ctrl agent
//  + scoreboard. Bank vifs are set by tb_top as "mem_vif_<b>".
// ============================================================
`ifndef VX_ENV_SV
`define VX_ENV_SV

class vx_env extends uvm_env;
  `uvm_component_utils(vx_env)

  localparam int NUM_BANKS = `VX_CFG_PLATFORM_MEMORY_NUM_BANKS;

  vx_mem_agent  mem_agents [NUM_BANKS];
  vx_dcr_agent  dcr_agent;
  vx_ctrl_agent ctrl_agent;
  vx_scoreboard scoreboard;
  vx_coverage   coverage;
  vx_dcr_cov_sub dcr_cov_sub;
  vx_mem_model  mem_model;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    mem_model = vx_mem_model::type_id::create("mem_model");
    uvm_config_db#(vx_mem_model)::set(this, "*", "mem_model", mem_model);
    for (int b = 0; b < NUM_BANKS; b++) begin
      virtual vx_mem_if vif;
      string an = $sformatf("mem_agent_%0d", b);
      if (!uvm_config_db#(virtual vx_mem_if)::get(this, "",
            $sformatf("mem_vif_%0d", b), vif))
        `uvm_fatal("ENV", $sformatf("no mem_vif_%0d", b))
      uvm_config_db#(virtual vx_mem_if)::set(this, an, "vif", vif);
      uvm_config_db#(int unsigned)::set(this, an, "bank_id", b);
      uvm_config_db#(int unsigned)::set(this, an, "num_banks", NUM_BANKS);
      mem_agents[b] = vx_mem_agent::type_id::create(an, this);
    end
    dcr_agent  = vx_dcr_agent::type_id::create("dcr_agent", this);
    ctrl_agent = vx_ctrl_agent::type_id::create("ctrl_agent", this);
    scoreboard = vx_scoreboard::type_id::create("scoreboard", this);
    coverage   = vx_coverage::type_id::create("coverage", this);
    dcr_cov_sub = vx_dcr_cov_sub::type_id::create("dcr_cov_sub", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    for (int b = 0; b < NUM_BANKS; b++) begin
      mem_agents[b].monitor.ap.connect(scoreboard.mem_imp);
      mem_agents[b].monitor.ap.connect(coverage.mem_imp);
    end
    dcr_cov_sub.cov = coverage;
    dcr_agent.monitor.ap.connect(dcr_cov_sub.analysis_export);
  endfunction
endclass

`endif
