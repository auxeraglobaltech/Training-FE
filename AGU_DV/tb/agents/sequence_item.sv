class agu_seq_item extends uvm_sequence_item;

   rand bit [31:0] src_addr;
   rand bit [31:0] dst_addr;

   rand bit [15:0] x_count;
   rand bit [15:0] y_count;

   rand bit signed [15:0] x_stride;
   rand bit signed [15:0] y_stride;

   rand bit [1:0] src_width;
   rand bit [1:0] dst_width;

   rand bit [3:0] burst_len;
   rand bit [1:0] burst_type;
   rand bit [1:0] addr_mode;

   rand bit [39:0] src_region_base;
   rand bit [39:0] src_region_limit;
   rand bit [39:0] dst_region_base;
   rand bit [39:0] dst_region_limit;

  rand bit enable_backpressure;
  rand int unsigned ready_low_pct; 
  `uvm_object_utils(agu_seq_item)
      function new(string name="agu_seq_item");
      super.new(name);
   endfunction
    constraint c_basic_valid {
    x_count inside {[1:16]};
    y_count inside {[1:8]};

    src_width == 2'b10; // 32-bit
    dst_width == 2'b10;

    burst_len inside {[1:8]};

    // 00 = FIXED, 01 = INCR
    burst_type inside {2'b00, 2'b01};
    addr_mode  inside {2'b00, 2'b01};

    src_addr[1:0] == 2'b00;
    dst_addr[1:0] == 2'b00;

    x_stride inside {16'sd0, 16'sd4, 16'sd8, 16'sd16};
    y_stride inside {16'sd0, 16'sd16, 16'sd32, 16'sd64, 16'sd128};

    src_region_base == 40'h0;
    dst_region_base == 40'h0;

    src_region_limit == 40'h00FF_FFFF;
    dst_region_limit == 40'h00FF_FFFF;

    ready_low_pct inside {[0:40]};
  }
   function bit [31:0] build_w0();
      bit [31:0] w0;
      w0 = '0;
      w0[22:21] = src_width;
      w0[20:19] = dst_width;
      w0[18:15] = burst_len;
      w0[14:13] = burst_type;
      w0[12:11] = addr_mode;
      return w0;
   endfunction

 function bit [31:0] build_w1();
    return src_addr;
  endfunction

  function bit [31:0] build_w2();
    return dst_addr;
  endfunction

  function bit [31:0] build_w3();
  return {x_count[15:0], x_stride[15:0]};
endfunction

function bit [31:0] build_w4();
  return {y_count[15:0], y_stride[15:0]};
endfunction
   
   endclass
