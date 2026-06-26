// ============================================================================
//  ddr_sequences.sv  —  Wishbone sequence library
// ============================================================================

class ddr_base_seq extends uvm_sequence #(wb_seq_item);
  `uvm_object_utils(ddr_base_seq)
  function new(string name="ddr_base_seq"); super.new(name); endfunction

  task do_write(bit [23:0] waddr, bit [127:0] wdata, bit [15:0] wsel = 16'hFFFF);
    wb_seq_item t = wb_seq_item::type_id::create("wr");
    start_item(t);
    t.we = 1'b1; t.addr = waddr; t.data = wdata; t.sel = wsel;
    finish_item(t);
  endtask

  task do_read(bit [23:0] raddr);
    wb_seq_item t = wb_seq_item::type_id::create("rd");
    start_item(t);
    t.we = 1'b0; t.addr = raddr; t.sel = 16'hFFFF;
    finish_item(t);
  endtask

  task wr_then_rd(bit [23:0] a, bit [127:0] d, bit [15:0] sel = 16'hFFFF);
    do_write(a, d, sel);
    do_read(a);
  endtask
endclass

// W+R to a handful of representative addresses (banks, rows, columns)
class ddr_sanity_seq extends ddr_base_seq;
  `uvm_object_utils(ddr_sanity_seq)
  function new(string name="ddr_sanity_seq"); super.new(name); endfunction
  task body();
    wr_then_rd(24'h00_0000, 128'hDEADBEEF_00112233_44556677_8899AABB);
    wr_then_rd(24'h00_0001, 128'h01234567_89ABCDEF_FEDCBA98_76543210);
    wr_then_rd(24'h00_0080, 128'hA5A5A5A5_5A5A5A5A_F0F0F0F0_0F0F0F0F); // different bank
    wr_then_rd(24'h00_8000, 128'h11111111_22222222_33333333_44444444); // different row
    wr_then_rd(24'h10_0000, 128'hCAFEBABE_DEADC0DE_8BADF00D_FEEDFACE);
  endtask
endclass

// byte-select / masked writes: baseline full write, then partial writes with
// various select patterns, each followed by a read (golden mem models PSTRB).
class ddr_bytesel_seq extends ddr_base_seq;
  `uvm_object_utils(ddr_bytesel_seq)
  function new(string name="ddr_bytesel_seq"); super.new(name); endfunction
  task body();
    bit [23:0] a = 24'h00_0040;
    bit [15:0] pats [] = '{16'h0001, 16'h8000, 16'h00FF, 16'hFF00, 16'hA5A5, 16'h0F0F};
    wr_then_rd(a, 128'hFFFFFFFF_FFFFFFFF_FFFFFFFF_FFFFFFFF);   // baseline
    foreach (pats[i]) begin
      bit [127:0] d = {$urandom,$urandom,$urandom,$urandom};
      do_write(a, d, pats[i]);     // partial write (only selected bytes change)
      do_read(a);                  // scoreboard checks merged result
    end
  endtask
endclass

// bank / row / column walk: exercise the {row,bank,col} address decode
class ddr_walk_seq extends ddr_base_seq;
  `uvm_object_utils(ddr_walk_seq)
  function new(string name="ddr_walk_seq"); super.new(name); endfunction
  task body();
    // walk all 8 banks (bank = word-addr[9:7])
    for (int bk=0; bk<8; bk++) begin
      bit [23:0] a = (bk << 7) | 24'h5;
      wr_then_rd(a, 128'hBA0000_00 | (bk<<24) | bk);
    end
    // walk a few rows (row = word-addr[23:10])
    for (int r=0; r<8; r++) begin
      bit [23:0] a = (r << 13);   // step rows
      wr_then_rd(a, 128'hF0F0_0000 | r);
    end
    // walk columns within a row (col = word-addr[6:0])
    for (int c=0; c<16; c++)
      wr_then_rd(24'h01_0000 | c, 128'hC01_00000 | c);
  endtask
endclass

// randomised mixed traffic across a bounded address window
class ddr_random_seq extends ddr_base_seq;
  `uvm_object_utils(ddr_random_seq)
  rand int unsigned num = 50;
  function new(string name="ddr_random_seq"); super.new(name); endfunction
  task body();
    bit [127:0] shadow [bit [23:0]];   // ensure reads target written addresses
    repeat (num) begin
      bit [23:0] a = $urandom_range(0, 'hFFFF);
      if ($urandom_range(0,1) || !shadow.exists(a)) begin
        bit [127:0] d = {$urandom,$urandom,$urandom,$urandom};
        do_write(a, d); shadow[a]=d;
      end else begin
        do_read(a);
      end
    end
  endtask
endclass
