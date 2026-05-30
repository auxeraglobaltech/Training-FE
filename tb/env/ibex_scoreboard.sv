class ibex_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(ibex_scoreboard)

  uvm_analysis_imp #(logic [31:0], ibex_scoreboard) analysis_export;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    analysis_export = new("analysis_export", this);
  endfunction

  function void write(logic [31:0] val);
    if (val == 32'h1)
      `uvm_info("SB", "PASS: tohost=1", UVM_LOW)
    else
      `uvm_error("SB", "FAIL: tohost!=1")
  endfunction

endclass
