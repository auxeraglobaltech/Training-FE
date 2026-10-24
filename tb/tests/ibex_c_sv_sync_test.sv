// SV half of sw/tests/c_sv_handshake.c.
//
// The base test already forwards every C sv_sync() call here; this test
// only defines what each command does. Whatever runs inside a case
// branch - waits, interface pokes, sequences - happens while C is
// paused in sv_sync(), and C resumes only after the branch returns.
//
// Run:  make sim TEST=c_sv_handshake TEST_NAME=ibex_c_sv_sync_test
class ibex_c_sv_sync_test extends ibex_base_test;
  `uvm_component_utils(ibex_c_sv_sync_test)

  // Command ids - must match the #defines in c_sv_handshake.c.
  localparam logic [31:0] CMD_SV_WAIT    = 1;
  localparam logic [31:0] CMD_SV_COMPUTE = 2;
  localparam logic [31:0] CMD_IRQ_ON     = 3;
  localparam logic [31:0] CMD_IRQ_OFF    = 4;

  localparam int unsigned IRQ_LINE_EXTERNAL = 2;   // sw/common/irqmbox.h

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual task handle_c_cmd(logic [31:0] cmd, logic [31:0] arg,
                            output logic [31:0] result);
    case (cmd)
      CMD_SV_WAIT: begin
        `uvm_info("SV", $sformatf("part 1: C is paused, SV runs for %0d clocks", arg), UVM_NONE)
        repeat (arg) @(posedge vif.clk);
        `uvm_info("SV", "part 1: done, releasing C", UVM_NONE)
        result = arg;
      end
      CMD_SV_COMPUTE: begin
        result = arg * 2 + 1;
        `uvm_info("SV", $sformatf("part 2: got %0d from C, returning %0d", arg, result), UVM_NONE)
      end
      CMD_IRQ_ON: begin
        `uvm_info("SV", "part 3: driving irq_external_i = 1", UVM_NONE)
        env.agent.drv.poke_irq(IRQ_LINE_EXTERNAL, 1);
        result = 1;
      end
      CMD_IRQ_OFF: begin
        `uvm_info("SV", "part 3: driving irq_external_i = 0", UVM_NONE)
        env.agent.drv.poke_irq(IRQ_LINE_EXTERNAL, 0);
        result = 0;
      end
      default: super.handle_c_cmd(cmd, arg, result);
    endcase
  endtask

endclass
