// ============================================================
//  Ctrl agent: drives the 1-cycle start pulse, monitors busy.
//  wait_done() implements the stable-idle completion check proven in
//  tb_top_vx_smoke (busy can be discontinuous across KMU phases).
// ============================================================
`ifndef VX_CTRL_AGENT_SV
`define VX_CTRL_AGENT_SV

class vx_ctrl_agent extends uvm_agent;
  `uvm_component_utils(vx_ctrl_agent)

  virtual vx_ctrl_if vif;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual vx_ctrl_if)::get(this, "", "vif", vif))
      `uvm_fatal("CTRL_AGT", "no vif")
  endfunction

  task pulse_start();
    @(negedge vif.clk); vif.start <= 1'b1;
    @(negedge vif.clk); vif.start <= 1'b0;
  endtask

  // wait busy rise, then stable-low for idle_confirm cycles
  task wait_done(input int idle_confirm = 100);
    int idle = 0;
    wait (vif.busy === 1'b1);
    `uvm_info("CTRL", $sformatf("busy asserted @%0t", $time), UVM_LOW)
    while (idle < idle_confirm) begin
      @(posedge vif.clk);
      if (vif.busy === 1'b0) idle++;
      else                   idle = 0;
    end
    `uvm_info("CTRL", $sformatf("busy deasserted (stable) @%0t", $time), UVM_LOW)
  endtask
endclass

`endif
