class ibex_monitor extends uvm_monitor;
  `uvm_component_utils(ibex_monitor)

  virtual ibex_if vif;
  uvm_analysis_port #(logic [31:0]) ap;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual ibex_if)::get(this, "", "vif", vif))
      `uvm_fatal("MON", "No virtual interface found in config_db")
    ap = new("ap", this);
  endfunction

  task run_phase(uvm_phase phase);
    forever begin
      @(posedge vif.clk);
      if (vif.data_req && vif.data_we && vif.data_addr == 32'h00010000) begin
        ap.write(vif.data_wdata);
      end
    end
  endtask

endclass
