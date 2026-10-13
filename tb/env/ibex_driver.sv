class ibex_driver extends uvm_driver #(uvm_sequence_item);
  `uvm_component_utils(ibex_driver)

  virtual ibex_if vif;

  // Mailbox-driven IRQ line state, indexed per sw/common/irqmbox.h:
  // 0=software, 1=timer, 2=external, 3=nmi, 4..18=fast0..14.
  logic [18:0] irq_state;

  localparam logic [31:0] IRQ_CTRL_ADDR = 32'h0001_0004;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual ibex_if)::get(this, "", "vif", vif))
      `uvm_fatal("DRV", "No virtual interface found in config_db")
  endfunction

  // Sets or clears exactly one irq line, leaving the others untouched.
  // Kept as its own task so a future UVM sequence can drive these same
  // lines (e.g. for OBI back-pressure testing) without touching the
  // irq_state bit logic.
  task poke_irq(int unsigned line_id, bit on);
    irq_state[line_id] = on;
    vif.irq_software <= irq_state[0];
    vif.irq_timer    <= irq_state[1];
    vif.irq_external <= irq_state[2];
    vif.irq_nm       <= irq_state[3];
    vif.irq_fast     <= irq_state[18:4];
  endtask

  // Watches the data bus for writes to the irq_ctrl mailbox - same
  // passive-tap style ibex_monitor.sv already uses for tohost - and
  // decodes bit[31]=assert/deassert, bits[4:0]=line_id.
  task watch_irq_mailbox();
    forever begin
      @(posedge vif.clk);
      if (vif.data_req && vif.data_we &&
          {vif.data_addr[31:2], 2'b00} == IRQ_CTRL_ADDR) begin
        poke_irq(vif.data_wdata[4:0], vif.data_wdata[31]);
      end
    end
  endtask

  task run_phase(uvm_phase phase);
    irq_state        = '0;
    vif.irq_software <= 1'b0;
    vif.irq_timer    <= 1'b0;
    vif.irq_external <= 1'b0;
    vif.irq_fast     <= 15'h0;
    vif.irq_nm       <= 1'b0;
    vif.debug_req    <= 1'b0;
    vif.rst_n        <= 1'b0;
    repeat (10) @(posedge vif.clk);
    vif.rst_n <= 1'b1;
    fork
      watch_irq_mailbox();
    join_none
    wait (1'b0);  // wait forever
  endtask

endclass
