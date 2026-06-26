// ============================================================================
//  wb_seq_item.sv  —  one Wishbone (DDR3 word) transaction
// ============================================================================
class wb_seq_item extends uvm_sequence_item;

  rand bit                  we;       // 1 = write, 0 = read
  rand bit [23:0]           addr;     // word address {row,bank,col}
  rand bit [127:0]          data;     // write data
  rand bit [15:0]           sel;      // byte select (writes)
  bit [15:0]                aux;      // tag (set by driver)

  // filled on completion
  bit [127:0]               rdata;    // read data
  bit                       err;      // wb_err

  `uvm_object_utils_begin(wb_seq_item)
    `uvm_field_int(we,    UVM_ALL_ON)
    `uvm_field_int(addr,  UVM_ALL_ON)
    `uvm_field_int(data,  UVM_ALL_ON)
    `uvm_field_int(sel,   UVM_ALL_ON)
    `uvm_field_int(aux,   UVM_ALL_ON)
    `uvm_field_int(rdata, UVM_ALL_ON)
  `uvm_object_utils_end

  function new(string name="wb_seq_item"); super.new(name); endfunction

  // Directed sequences set we/addr/data/sel explicitly, so no rand constraints
  // are needed here (full-word sel is the default, partial-byte writes override).

endclass : wb_seq_item
