// Decodes the C test's single tohost store (sw/common/test_end.h):
//   0x0000_0001         PASS
//   0xFA11_xxxx         FAIL reported by the C test, code = xxxx
//   anything else       FAIL - unexpected trap (value is mcause) or a
//                       legacy raw fail code
//   never written       FAIL - TIMEOUT (checked in check_phase, which
//                       only runs when the base-test watchdog expires;
//                       a tohost store ends the sim via $finish first)
class ibex_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(ibex_scoreboard)

  uvm_analysis_imp #(logic [31:0], ibex_scoreboard) analysis_export;

  bit tohost_seen;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    analysis_export = new("analysis_export", this);
  endfunction

  function void write(logic [31:0] val);
    tohost_seen = 1;
    if (val == 32'h1)
      `uvm_info("SB", "TEST PASSED (tohost=1)", UVM_NONE)
    else if (val[31:16] == 16'hFA11)
      `uvm_error("SB", $sformatf(
        "TEST FAILED - C test reported fail code %0d (0x%04h)",
        val[15:0], val[15:0]))
    else
      `uvm_error("SB", $sformatf(
        "TEST FAILED - tohost=0x%08h: unexpected trap (%s cause=%0d) or legacy fail code",
        val, val[31] ? "interrupt" : "exception", val[30:0]))
  endfunction

  function void check_phase(uvm_phase phase);
    if (!tohost_seen)
      `uvm_error("SB", "TEST FAILED - TIMEOUT: C test never wrote tohost")
  endfunction

endclass
