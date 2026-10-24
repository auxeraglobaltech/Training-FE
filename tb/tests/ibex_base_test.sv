class ibex_base_test extends uvm_test;
  `uvm_component_utils(ibex_base_test)

  ibex_env        env;
  virtual ibex_if vif;

  // Watchdog: if the C test never writes tohost, the run ends here and
  // the scoreboard reports TIMEOUT. Override with +TIMEOUT_NS=<n>.
  longint unsigned timeout_ns = 1_000_000;   // 1 ms

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual ibex_if)::get(this, "", "vif", vif))
      `uvm_fatal("TEST", "No virtual interface found in config_db")
    void'($value$plusargs("TIMEOUT_NS=%d", timeout_ns));
    env = ibex_env::type_id::create("env", this);
  endfunction

  task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    fork
      serve_c_cmds();
    join_none
    #(timeout_ns * 1ns);
    phase.drop_objection(this);
  endtask

  // C <-> SV handshake loop (sw/common/c2sv.h): every sv_sync() from C
  // lands here, runs handle_c_cmd(), and is answered with its result.
  task serve_c_cmds();
    logic [31:0] cmd, arg, result;
    forever begin
      env.c2sv.get_cmd(cmd, arg);
      result = '0;
      handle_c_cmd(cmd, arg, result);
      env.c2sv.reply(cmd, result);
    end
  endtask

  // Override in a derived test to give each command id its SV behaviour.
  // The default just acknowledges, so a C test calling sv_sync() under
  // the plain base test never hangs.
  virtual task handle_c_cmd(logic [31:0] cmd, logic [31:0] arg,
                            output logic [31:0] result);
    `uvm_warning("C2SV", $sformatf(
      "cmd=%0d arg=0x%08h has no SV handler in %s - acking with 0",
      cmd, arg, get_type_name()))
    result = '0;
  endtask

endclass
