// ============================================================
//  vx_base_test: load +KERNEL image -> boot DCRs -> start -> wait busy
//  (stable-idle) -> cache flush -> scoreboard checks exit code.
//  Derived tests override the kernel / expected value / sequences.
// ============================================================
`ifndef VX_BASE_TEST_SV
`define VX_BASE_TEST_SV

class vx_base_test extends uvm_test;
  `uvm_component_utils(vx_base_test)

  vx_env env;
  string kernel_path;
  longint unsigned watchdog_cycles = 2_000_000;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = vx_env::type_id::create("env", this);
    if (!$value$plusargs("KERNEL=%s", kernel_path))
      `uvm_fatal("TEST", "no +KERNEL=<hex> given")
  endfunction

  function void end_of_elaboration_phase(uvm_phase phase);
    env.mem_model.load_hex(kernel_path);
  endfunction

  task run_phase(uvm_phase phase);
    vx_boot_seq  boot;
    vx_flush_seq flush;
    phase.raise_objection(this);

    // reset done in tb_top; wait for it to release
    @(negedge env.ctrl_agent.vif.reset);
    repeat (`VX_CFG_RESET_DELAY) @(posedge env.ctrl_agent.vif.clk);

    boot = vx_boot_seq::type_id::create("boot");
    boot.start(env.dcr_agent.sequencer);

    env.ctrl_agent.pulse_start();

    fork : run_wait
      begin
        env.ctrl_agent.wait_done();
        disable run_wait;
      end
      begin
        repeat (watchdog_cycles) @(posedge env.ctrl_agent.vif.clk);
        `uvm_error("TEST", $sformatf(
          "watchdog: busy did not complete in %0d cycles", watchdog_cycles))
        disable run_wait;
      end
    join

    flush = vx_flush_seq::type_id::create("flush");
    flush.num_cores = `VX_CFG_NUM_CLUSTERS * `VX_CFG_NUM_CORES;
    flush.start(env.dcr_agent.sequencer);
    repeat (200) @(posedge env.ctrl_agent.vif.clk);  // drain writebacks

    phase.drop_objection(this);
  endtask
endclass

`endif
