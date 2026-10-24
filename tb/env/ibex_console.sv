// Prints the C program's console output (sw/common/print.h).
//
// Passive tap, same style as ibex_monitor: every store to CONSOLE_TX
// carries one character in wdata[7:0]. Characters are collected into a
// line and printed when C sends '\n', so a C-side
//     printf("x=%d\n", x);
// shows up in the log as one line:
//     UVM_INFO ... [C_PRINT] x=5
class ibex_console extends uvm_component;
  `uvm_component_utils(ibex_console)

  localparam logic [31:0] CONSOLE_TX = 32'h0003_0000;

  virtual ibex_if vif;
  string          line;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual ibex_if)::get(this, "", "vif", vif))
      `uvm_fatal("CONSOLE", "No virtual interface found in config_db")
  endfunction

  task run_phase(uvm_phase phase);
    byte c;
    forever begin
      @(vif.mon_cb);
      if (vif.mon_cb.data_req && vif.mon_cb.data_we &&
          {vif.mon_cb.data_addr[31:2], 2'b00} == CONSOLE_TX) begin
        c = vif.mon_cb.data_wdata[7:0];
        if (c == "\n") begin
          `uvm_info("C_PRINT", line, UVM_NONE)
          line = "";
        end else if (c != 8'h0D) begin      // drop CR (SV has no "\r" escape)
          line = {line, string'(c)};
        end
      end
    end
  endtask

endclass
