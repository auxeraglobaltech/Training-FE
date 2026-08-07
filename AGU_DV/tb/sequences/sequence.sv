class agu_seq extends uvm_sequence#(agu_seq_item);
  `uvm_object_utils(agu_seq)
      //constructor
  function new(string name="agu_seq");
     super.new();
  endfunction
task body();
 `uvm_info("BASE_SEQ","Base sequence body",UVM_LOW)
endtask
endclass
class agu_basic_2d_seq extends agu_seq;
`uvm_object_utils(agu_basic_2d_seq)
function new(string name="agu_basic_2d_seq");
super.new(name);
endfunction
task body();
agu_seq_item txn;
txn=agu_seq_item::type_id::create("txn");
start_item(txn);
assert(txn.randomize() with {

      src_addr == 32'h0000_1000;
      dst_addr == 32'h0000_8000;

      x_count  == 16'd4;
      y_count  == 16'd3;

      x_stride == 16'sd4;
      y_stride == 16'sd64;

      src_width == 2'b10;   // 32-bit
      dst_width == 2'b10;

      burst_len  == 4'd1;
      burst_type == 2'b01;  // INCR
      addr_mode  == 2'b01;  // INCR/stride mode

      src_region_base  == 40'h0;
      src_region_limit == 40'h00FF_FFFF;

      dst_region_base  == 40'h0;
      dst_region_limit == 40'h00FF_FFFF;

      enable_backpressure == 0;
      ready_low_pct       == 0;
    })
else begin
    `uvm_error("AGU_SEQ","Randomization failed for agu_basic_2d_sequence")
    end
    finish_item(txn);
    endtask
    endclass

    class agu_basic_1d_sequence extends agu_seq;

  `uvm_object_utils(agu_basic_1d_sequence)

  function new(string name = "agu_basic_1d_sequence");
    super.new(name);
  endfunction

  virtual task body();

    agu_seq_item txn;

    txn = agu_seq_item::type_id::create("txn");

    start_item(txn);

    // ------------------------------------------------------------
    // Basic one-dimensional AGU transfer
    // ------------------------------------------------------------

    txn.src_addr = 32'h0000_1000;
    txn.dst_addr = 32'h0000_8000;

    // Four elements in one row
    txn.x_count = 16'd4;

    // Critical condition for the 1D test
    txn.y_count = 16'd1;

    // Move by four bytes after each element
    txn.x_stride = 16'sd4;

    // No second row exists, so Y stride is unused
    txn.y_stride = 16'sd0;

    // 32-bit source and destination access
    txn.src_width = 2'b10;
    txn.dst_width = 2'b10;

    // Keep the same legal values used by the basic 2D test
    txn.burst_len  = 4'd1;
    txn.burst_type = 2'b01;  // INCR

    // Use the same address mode that passed in the 2D test.
    // Based on your current descriptor, this is likely STRIDE mode.
    txn.addr_mode = 2'b01;

    // No backpressure in the basic 1D test
    txn.enable_backpressure = 1'b0;
    txn.ready_low_pct       = 0;

    // MPU regions contain both source and destination addresses
    txn.src_region_base  = 40'h0000_0000_00;
    txn.src_region_limit = 40'h0000_00FF_FFFF;

    txn.dst_region_base  = 40'h0000_0000_00;
    txn.dst_region_limit = 40'h0000_00FF_FFFF;

    finish_item(txn);

    `uvm_info(
      "AGU_1D_SEQ",
      $sformatf(
        {"Generated 1D transaction: ",
         "SRC=0x%0h DST=0x%0h ",
         "X_COUNT=%0d Y_COUNT=%0d ",
         "X_STRIDE=%0d Y_STRIDE=%0d"},
        txn.src_addr,
        txn.dst_addr,
        txn.x_count,
        txn.y_count,
        txn.x_stride,
        txn.y_stride
      ),
      UVM_MEDIUM
    )

  endtask

endclass

class agu_fixed_addr_sequence extends agu_seq;

  `uvm_object_utils(agu_fixed_addr_sequence)

  function new(string name="agu_fixed_addr_sequence");
    super.new(name);
  endfunction

  virtual task body();

    agu_seq_item txn;

    txn = agu_seq_item::type_id::create("txn");

    start_item(txn);

    txn.src_addr = 32'h1000;
    txn.dst_addr = 32'h8000;

    txn.x_count = 4;
    txn.y_count = 3;

    txn.x_stride = 0;
    txn.y_stride = 0;

    txn.src_width = 2'b10;
    txn.dst_width = 2'b10;

    txn.burst_len = 4'd1;

    txn.burst_type = 2'b00;

    //-------------------------------------------------------
    // FIXED ADDRESS MODE
    //-------------------------------------------------------

    txn.addr_mode = 2'b01;

    txn.enable_backpressure = 0;
    txn.ready_low_pct = 0;

    txn.src_region_base  = 40'h0;
    txn.src_region_limit = 40'h0000_00FF_FFFF;

    txn.dst_region_base  = 40'h0;
    txn.dst_region_limit = 40'h0000_00FF_FFFF;

    finish_item(txn);

  endtask

endclass

