// ============================================================================
//  apb_seq_item.sv  —  one observed APB transfer (from the APB monitor)
// ----------------------------------------------------------------------------
//  The APB slaves are reactive; this item is produced by the APB monitor so
//  the scoreboard can reconcile each AXI-burst beat against the APB transfers
//  the bridge actually generated.
// ============================================================================
class apb_seq_item extends uvm_sequence_item;

  bit [31:0] addr;
  bit [2:0]  prot;
  bit        write;
  bit [31:0] wdata;
  bit [3:0]  strb;
  bit [31:0] rdata;
  bit        slverr;

  `uvm_object_utils_begin(apb_seq_item)
    `uvm_field_int(addr,   UVM_ALL_ON)
    `uvm_field_int(write,  UVM_ALL_ON)
    `uvm_field_int(wdata,  UVM_ALL_ON)
    `uvm_field_int(strb,   UVM_ALL_ON)
    `uvm_field_int(rdata,  UVM_ALL_ON)
    `uvm_field_int(slverr, UVM_ALL_ON)
  `uvm_object_utils_end

  function new(string name = "apb_seq_item");
    super.new(name);
  endfunction

endclass : apb_seq_item
