class ibex_driver extends uvm_driver #(uvm_sequence_item);
  `uvm_component_utils(ibex_driver)

  virtual ibex_if vif;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual ibex_if)::get(this, "", "vif", vif))
      `uvm_fatal("DRV", "No virtual interface found in config_db")
  endfunction

  task run_phase(uvm_phase phase);
    vif.irq_software <= 1'b0;
    vif.irq_timer    <= 1'b0;
    vif.irq_external <= 1'b0;
    vif.irq_fast     <= 15'h0;
    vif.irq_nm       <= 1'b0;
    vif.debug_req    <= 1'b0;
    vif.rst_n        <= 1'b0;
    repeat (10) @(posedge vif.clk);
    vif.rst_n <= 1'b1;
    wait (1'b0);  // wait forever
  endtask

endclass
