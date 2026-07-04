// ============================================================
//  DCR sequences: KMU boot programming + cache-flush read.
//  Register table from dv/docs/boot_dcr_notes.md (main.cpp contract).
// ============================================================
`ifndef VX_SEQUENCES_SV
`define VX_SEQUENCES_SV

class vx_dcr_base_seq extends uvm_sequence #(vx_dcr_txn);
  `uvm_object_utils(vx_dcr_base_seq)
  function new(string name = "vx_dcr_base_seq");
    super.new(name);
  endfunction

  task dcr_write(bit [11:0] addr, bit [31:0] data);
    vx_dcr_txn t = vx_dcr_txn::type_id::create("t");
    start_item(t);
    t.rw = 1'b1; t.addr = addr; t.data = data;
    finish_item(t);
  endtask

  task dcr_read(bit [11:0] addr, bit [31:0] tag, output bit [31:0] rsp);
    vx_dcr_txn t = vx_dcr_txn::type_id::create("t");
    start_item(t);
    t.rw = 1'b0; t.addr = addr; t.data = tag;
    finish_item(t);
    rsp = t.rsp_data;
  endtask
endclass

// KMU boot programming: 1x1x1 grid/block, startup addr, warp step
class vx_boot_seq extends vx_dcr_base_seq;
  `uvm_object_utils(vx_boot_seq)

  bit [31:0] startup_addr = 32'h8000_0000;

  function new(string name = "vx_boot_seq");
    super.new(name);
  endfunction

  task body();
    dcr_write(12'h010, startup_addr);        // KMU_STARTUP_ADDR0
    dcr_write(12'h014, 32'd0);               // KMU_STARTUP_ARG0
    dcr_write(12'h015, 32'd0);               // KMU_STARTUP_ARG1
    dcr_write(12'h016, 32'd1);               // KMU_BLOCK_DIM_X
    dcr_write(12'h017, 32'd1);               // KMU_BLOCK_DIM_Y
    dcr_write(12'h018, 32'd1);               // KMU_BLOCK_DIM_Z
    dcr_write(12'h019, 32'd1);               // KMU_GRID_DIM_X
    dcr_write(12'h01A, 32'd1);               // KMU_GRID_DIM_Y
    dcr_write(12'h01B, 32'd1);               // KMU_GRID_DIM_Z
    dcr_write(12'h01C, 32'd0);               // KMU_LMEM_SIZE
    dcr_write(12'h01D, 32'd1);               // KMU_BLOCK_SIZE
    dcr_write(12'h01E, `VX_CFG_NUM_THREADS); // KMU_WARP_STEP_X
    dcr_write(12'h01F, 32'd0);               // KMU_WARP_STEP_Y
    dcr_write(12'h020, 32'd0);               // KMU_WARP_STEP_Z
    dcr_write(12'h021, 32'd1);               // KMU_CLUSTER_DIM_X
    dcr_write(12'h022, 32'd1);               // KMU_CLUSTER_DIM_Y
    dcr_write(12'h023, 32'd1);               // KMU_CLUSTER_DIM_Z
    `uvm_info("BOOT_SEQ", "KMU boot DCR programming done", UVM_LOW)
  endtask
endclass

// post-run cache flush: DCR read of BASE_CACHE_FLUSH per core (tag = core id)
class vx_flush_seq extends vx_dcr_base_seq;
  `uvm_object_utils(vx_flush_seq)

  int unsigned num_cores = 1;

  function new(string name = "vx_flush_seq");
    super.new(name);
  endfunction

  task body();
    bit [31:0] rsp;
    for (int unsigned c = 0; c < num_cores; c++)
      dcr_read(12'h000, c, rsp);             // BASE_CACHE_FLUSH
    `uvm_info("FLUSH_SEQ", "cache flush done", UVM_LOW)
  endtask
endclass

`endif
