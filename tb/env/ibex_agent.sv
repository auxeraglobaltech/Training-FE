class ibex_agent extends uvm_agent;
  `uvm_component_utils(ibex_agent)

  ibex_driver  drv;
  ibex_monitor mon;

  uvm_analysis_port #(logic [31:0]) ap;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    mon = ibex_monitor::type_id::create("mon", this);
    if (get_is_active() == UVM_ACTIVE)
      drv = ibex_driver::type_id::create("drv", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    ap = mon.ap;
  endfunction

endclass
