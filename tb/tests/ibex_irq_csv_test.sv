// SV half of the sw/tests/irq_csv_*.c interrupt tests (C side of the
// commands: sw/common/irq_csv.h).
//
// C configures the core (mie, mstatus) and then asks SV, over the C <-> SV
// handshake, to drive interrupt pins on the DUT. The ISR in C asks SV to
// drop the pin again. SV never decides *when* - C owns the flow.
//
// Run:  make sim TEST=irq_csv_single TEST_NAME=ibex_irq_csv_test
class ibex_irq_csv_test extends ibex_base_test;
  `uvm_component_utils(ibex_irq_csv_test)

  // Command ids - must match the #defines in sw/common/irq_csv.h.
  localparam logic [31:0] CMD_IRQ_RAISE      = 32'h10;
  localparam logic [31:0] CMD_IRQ_CLEAR      = 32'h11;
  localparam logic [31:0] CMD_IRQ_RAISE_MASK = 32'h12;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  // Line id -> name, for readable log messages (ids: sw/common/irqmbox.h).
  function string line_name(int unsigned line);
    case (line)
      0:       return "software";
      1:       return "timer";
      2:       return "external";
      3:       return "nmi";
      default: return $sformatf("fast%0d", line - 4);
    endcase
  endfunction

  virtual task handle_c_cmd(logic [31:0] cmd, logic [31:0] arg,
                            output logic [31:0] result);
    int unsigned line, delay;
    case (cmd)
      CMD_IRQ_RAISE: begin
        line  = arg[4:0];
        delay = arg[31:16];
        `uvm_info("SV", $sformatf("raise %s in %0d clocks (C released now)",
                                  line_name(line), delay), UVM_NONE)
        // Returning from handle_c_cmd releases C; the pin goes high later,
        // while C is running its own code (see irq_csv.h for why).
        fork
          begin
            repeat (delay) @(posedge vif.clk);
            `uvm_info("SV", $sformatf("irq %s -> 1", line_name(line)), UVM_NONE)
            env.agent.drv.poke_irq(line, 1);
          end
        join_none
        result = 0;
      end
      CMD_IRQ_CLEAR: begin
        line = arg[4:0];
        `uvm_info("SV", $sformatf("irq %s -> 0 (ISR asked)", line_name(line)), UVM_NONE)
        env.agent.drv.poke_irq(line, 0);
        @(posedge vif.clk);   // pin is low before C is released
        result = 0;
      end
      CMD_IRQ_RAISE_MASK: begin
        for (int unsigned l = 0; l < 19; l++)
          if (arg[l]) begin
            `uvm_info("SV", $sformatf("irq %s -> 1 (mask)", line_name(l)), UVM_NONE)
            env.agent.drv.poke_irq(l, 1);
          end
        @(posedge vif.clk);
        result = 0;
      end
      default: super.handle_c_cmd(cmd, arg, result);
    endcase
  endtask

endclass
