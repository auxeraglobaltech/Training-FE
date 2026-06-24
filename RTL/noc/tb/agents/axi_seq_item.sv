// ============================================================================
//  axi_seq_item.sv  —  one AXI transaction (read or write burst)
// ----------------------------------------------------------------------------
//  Carries everything a master drives and the response it receives.  ID is
//  stored in a generic 8-bit field so the same item can describe master-side
//  (4-bit) and slave-side (5-bit remapped) observations.
// ============================================================================
class axi_seq_item extends uvm_sequence_item;

  rand bit [7:0]              id;
  rand bit [31:0]            addr;
  rand bit [7:0]             len;     // AxLEN = beats-1
  rand bit [2:0]             size;    // AxSIZE = log2(bytes/beat)
  rand bit [1:0]             burst;   // 01 = INCR
  rand bit [3:0]             qos;
  rand bit                   is_write;
  rand bit [31:0]            data [];  // per beat (write data / captured read data)
  rand bit [3:0]             strb [];  // per beat write strobe

  // ---- response (filled by monitor / driver) ----
  bit [1:0]                  resp;        // B resp, or last-beat R resp
  bit [1:0]                  rresp_beat[];// per-beat read response

  `uvm_object_utils_begin(axi_seq_item)
    `uvm_field_int(id,       UVM_ALL_ON)
    `uvm_field_int(addr,     UVM_ALL_ON)
    `uvm_field_int(len,      UVM_ALL_ON)
    `uvm_field_int(size,     UVM_ALL_ON)
    `uvm_field_int(burst,    UVM_ALL_ON)
    `uvm_field_int(qos,      UVM_ALL_ON)
    `uvm_field_int(is_write, UVM_ALL_ON)
    `uvm_field_array_int(data, UVM_ALL_ON)
    `uvm_field_array_int(strb, UVM_ALL_ON)
    `uvm_field_int(resp,     UVM_ALL_ON)
  `uvm_object_utils_end

  function new(string name = "axi_seq_item");
    super.new(name);
  endfunction

  // INCR bursts, <=4-byte beats, sized data array, 4KB-safe, size-aligned addr.
  constraint c_burst   { burst == 2'b01; }
  constraint c_size    { size  <= 3'd2; }
  constraint c_len     { len   inside {[0:7]}; }
  constraint c_dsize   { data.size() == len + 1; strb.size() == len + 1; }
  constraint c_align   { (addr % (1 << size)) == 0; }
  constraint c_no4k    { ((addr & 32'hFFF) + ((len + 1) << size)) <= 13'h1000; }

  function void post_randomize();
    if (is_write) foreach (strb[i]) strb[i] = 4'hF;   // full-word writes by default
  endfunction

endclass : axi_seq_item
