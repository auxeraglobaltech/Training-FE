class agu_driver extends uvm_driver #(agu_seq_item);
`uvm_component_utils(agu_driver)
 virtual agu_if vif;
 agu_seq_item txn;
 int unsigned timeout_count;
 int unsigned max_timeout_count = 5000;
 function new(string name = "agu_driver", uvm_component parent = null);
    super.new(name, parent);
  endfunction
function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if(!uvm_config_db#(virtual agu_if)::get(this,"","vif",vif))
        begin
        `uvm_fatal("AGU_DRV","Virtual Interface not found in agu driver")
        end
        endfunction
 task run_phase(uvm_phase phase);

    drive_idle();

    // Wait for reset release
    wait(vif.rst_n == 1'b1);
    repeat(2) @(posedge vif.clk);

    forever begin
      seq_item_port.get_next_item(txn);
      `uvm_info("AGU_DRV",$sformatf("Received AGU transaction:SRC=%0h DST=%0h X_COUNT=%0d Y_COUNT=%0d X_STRIDE=%0d Y_STRIDE=%0d",txn.src_addr,txn.dst_addr,txn.x_count,txn.y_count,txn.x_stride,txn.y_stride),UVM_MEDIUM)
       drive_transfer(txn);
       seq_item_port.item_done();
    end

  endtask

 task drive_idle();

    vif.start_i     <= 1'b0;
    vif.stop_i      <= 1'b0;
    vif.clr_fault_i <= 1'b0;

    vif.desc_w0_i <= 32'h0;
    vif.desc_w1_i <= 32'h0;
    vif.desc_w2_i <= 32'h0;
    vif.desc_w3_i <= 32'h0;
    vif.desc_w4_i <= 32'h0;
    vif.desc_w5_i <= 32'h0;
    vif.desc_w6_i <= 32'h0;

    vif.src_region_base_i  <= 40'h0;
    vif.src_region_limit_i <= 40'h00FF_FFFF;
    vif.dst_region_base_i  <= 40'h0;
    vif.dst_region_limit_i <= 40'h00FF_FFFF;

    vif.issue_ready_i     <= 1'b1;
    vif.issue_ack_i       <= 1'b0;
    vif.outstanding_cnt_i <= 4'h0;

  endtask

  // Main transaction task will be implemented in Part 2
  extern task drive_transfer(agu_seq_item txn);

  // Descriptor programming task will be implemented in Part 2
  extern task program_descriptor(agu_seq_item txn);

  // Start pulse task will be implemented in Part 2
  extern task send_start_pulse();

  // Issue handshake/backpressure tasks will be implemented in Part 3
  extern task drive_issue_channel(agu_seq_item txn);

  // Done/fault waiting task will be implemented in Part 4
  extern task wait_for_done_or_fault();

  // Fault clear task will be implemented in Part 4
  extern task clear_fault();

endclass
task agu_driver::drive_transfer(agu_seq_item txn);

  `uvm_info("AGU_DRV", "Starting AGU drive_transfer()", UVM_MEDIUM)

  vif.start_i       <= 1'b0;
  vif.stop_i        <= 1'b0;
  vif.clr_fault_i   <= 1'b0;
  vif.issue_ack_i   <= 1'b0;
  vif.issue_ready_i <= 1'b1;

  wait (vif.rst_n === 1'b1);
  repeat (2) @(posedge vif.clk);

  program_descriptor(txn);

  // Keep descriptor stable for two complete cycles.
  repeat (2) @(posedge vif.clk);

  send_start_pulse();

  fork : AGU_TRANSFER_THREADS
    drive_issue_channel(txn);
    wait_for_done_or_fault();
  join_any

  disable AGU_TRANSFER_THREADS;

  vif.start_i       <= 1'b0;
  vif.issue_ack_i   <= 1'b0;
  vif.issue_ready_i <= 1'b1;

  if (vif.fault_valid_o === 1'b1)
    clear_fault();

  repeat (2) @(posedge vif.clk);

endtask
task agu_driver::program_descriptor(agu_seq_item txn);
`uvm_info("AGU_DRV",$sformatf("Programing descriptor:W0=%0h W1=%0h W2=%0h W3=%0h W4=%0h",txn.build_w0(),txn.build_w1(),txn.build_w2(),txn.build_w3(),txn.build_w4()),UVM_MEDIUM)
@(negedge vif.clk);
vif.desc_w0_i<=txn.build_w0();
  // W1 = source base address
  vif.desc_w1_i <= txn.build_w1();

  // W2 = destination base address
  vif.desc_w2_i <= txn.build_w2();

  // W3 = {X_COUNT, X_STRIDE}
  vif.desc_w3_i <= txn.build_w3();

  // W4 = {Y_COUNT, Y_STRIDE}
  vif.desc_w4_i <= txn.build_w4();

  // W5/W6 currently unused for AGU top-level basic tests
  vif.desc_w5_i <= 32'd0;
  vif.desc_w6_i <= 32'd0;

  // MPU / bounds configuration
  vif.src_region_base_i  <= txn.src_region_base;
  vif.src_region_limit_i <= txn.src_region_limit;

  vif.dst_region_base_i  <= txn.dst_region_base;
  vif.dst_region_limit_i <= txn.dst_region_limit;

  // Default downstream ready
  vif.issue_ready_i     <= 1'b1;
  vif.issue_ack_i       <= 1'b0;
  vif.outstanding_cnt_i <= 4'h0;

endtask

task agu_driver::send_start_pulse();

  `uvm_info("AGU_DRV", "Sending start_i pulse", UVM_MEDIUM)

  // Assert before the active sampling edge.
  @(negedge vif.clk);
  vif.start_i <= 1'b1;

  // DUT sees start_i high at this posedge.
  @(posedge vif.clk);

  // Deassert after one complete sampled cycle.
  @(negedge vif.clk);
  vif.start_i <= 1'b0;

endtask
task agu_driver::drive_issue_channel(agu_seq_item txn);

  vif.issue_ack_i   <= 1'b0;
  vif.issue_ready_i <= 1'b1;

  forever begin

    // Drive ready before the DUT sampling edge.
    @(negedge vif.clk);

    if (txn.enable_backpressure) begin
      vif.issue_ready_i <=
        ($urandom_range(0, 99) >= txn.ready_low_pct);
    end
    else begin
      vif.issue_ready_i <= 1'b1;
    end

    // Sample DUT valid at the next positive edge.
    @(posedge vif.clk);

    if (vif.agu_done_o || vif.fault_valid_o) begin
      vif.issue_ack_i <= 1'b0;
      break;
    end

    if ((vif.agu_valid_o === 1'b1) &&
        (vif.issue_ready_i === 1'b1)) begin

      // Assert ACK before the next positive edge.
      @(negedge vif.clk);
      vif.issue_ack_i <= 1'b1;
   // Complete the handshake.
   @(posedge vif.clk);
      //Now sample accepted values

      `uvm_info(
        "AGU_DRV",
        $sformatf(
          "Address accepted: SRC=%0h DST=%0h BURST_BYTES=%0d",
          vif.agu_src_addr_o,
          vif.agu_dst_addr_o,
          vif.agu_burst_bytes_o
        ),
        UVM_MEDIUM
      )

      @(negedge vif.clk);
      vif.issue_ack_i <= 1'b0;
    end
    else begin
      vif.issue_ack_i <= 1'b0;
    end

  end

  vif.issue_ack_i   <= 1'b0;
  vif.issue_ready_i <= 1'b1;

endtask
task agu_driver::wait_for_done_or_fault();

  timeout_count = 0;

  forever begin
    @(posedge vif.clk);
    timeout_count++;

    if (vif.agu_done_o === 1'b1) begin
      `uvm_info(
        "AGU_DRV",
        $sformatf(
          "AGU completed after %0d cycles",
          timeout_count
        ),
        UVM_LOW
      )
      break;
    end

    if (vif.fault_valid_o === 1'b1) begin
      `uvm_error(
        "AGU_DRV",
        $sformatf(
          "AGU fault: code=0x%0h info=0x%0h after %0d cycles",
          vif.fault_code_o,
          vif.fault_info_o,
          timeout_count
        )
      )
      break;
    end

    if ((timeout_count % 100) == 0) begin
      `uvm_info(
        "AGU_DRV",
        $sformatf(
          {"Waiting: cycle=%0d rst=%0b start=%0b ",
           "valid=%0b ready=%0b ack=%0b done=%0b ",
           "fault=%0b src=%0h dst=%0h"},
          timeout_count,
          vif.rst_n,
          vif.start_i,
          vif.agu_valid_o,
          vif.issue_ready_i,
          vif.issue_ack_i,
          vif.agu_done_o,
          vif.fault_valid_o,
          vif.agu_src_addr_o,
          vif.agu_dst_addr_o
        ),
        UVM_MEDIUM
      )
    end

    if (timeout_count >= max_timeout_count) begin
      `uvm_error(
        "AGU_DRV",
        $sformatf(
          {"Timeout after %0d cycles: rst=%0b start=%0b ",
           "valid=%0b ready=%0b ack=%0b done=%0b ",
           "fault=%0b fault_code=0x%0h"},
          max_timeout_count,
          vif.rst_n,
          vif.start_i,
          vif.agu_valid_o,
          vif.issue_ready_i,
          vif.issue_ack_i,
          vif.agu_done_o,
          vif.fault_valid_o,
          vif.fault_code_o
        )
      )
      break;
    end

  end

endtask
task agu_driver::clear_fault();
`uvm_info("AGU_DRV","Clearing AGU Fault",UVM_LOW)
 @(posedge vif.clk);
  vif.clr_fault_i <= 1'b1;

  @(posedge vif.clk);
  vif.clr_fault_i <= 1'b0;
  repeat(2) 
  @(posedge vif.clk);
endtask

      
