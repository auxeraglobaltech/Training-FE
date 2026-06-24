// ============================================================================
//  noc_sequences.sv  —  sequence library for the NoC env
// ----------------------------------------------------------------------------
//  Master sequences run on an axi_master_sequencer; virtual sequences run on
//  the noc_vseqr and coordinate both masters (e.g. contention storms).
// ============================================================================

// ------------- base: helper to emit one write or one read -------------------
class axi_base_seq extends uvm_sequence #(axi_seq_item);
  `uvm_object_utils(axi_base_seq)
  function new(string name="axi_base_seq"); super.new(name); endfunction

  // one write burst to addr (random data), then one read burst same addr/len
  task wr_then_rd(bit [31:0] addr, int len = 0, bit [3:0] qos = 0);
    do_write(addr, len, qos);
    do_read (addr, len, qos);
  endtask

  task do_write(bit [31:0] waddr, int wlen = 0, bit [3:0] wqos = 0);
    axi_seq_item r = axi_seq_item::type_id::create("wr");
    start_item(r);
    if (!r.randomize() with {
          is_write == 1'b1; size == 3'd2; burst == 2'b01;
          addr == waddr; len == wlen; qos == wqos;
        }) `uvm_error("SEQ","wr randomize failed")
    finish_item(r);
  endtask

  task do_read(bit [31:0] raddr, int rlen = 0, bit [3:0] rqos = 0);
    axi_seq_item r = axi_seq_item::type_id::create("rd");
    start_item(r);
    if (!r.randomize() with {
          is_write == 1'b0; size == 3'd2; burst == 2'b01;
          addr == raddr; len == rlen; qos == rqos;
        }) `uvm_error("SEQ","rd randomize failed")
    finish_item(r);
  endtask
endclass

// ------------- connectivity: W+R to every target + DECERR -------------------
class connectivity_seq extends axi_base_seq;
  `uvm_object_utils(connectivity_seq)
  function new(string name="connectivity_seq"); super.new(name); endfunction
  task body();
    wr_then_rd(noc_pkg::S0_BASE + 32'h100, 0);
    wr_then_rd(noc_pkg::S1_BASE + 32'h200, 1);
    wr_then_rd(noc_pkg::P0_BASE + 32'h040, 0);
    wr_then_rd(noc_pkg::P1_BASE + 32'h080, 2);
    wr_then_rd(noc_pkg::S0_BASE + 32'h800, 3);   // a burst
    // unmapped -> DECERR (scoreboard expects it)
    do_write(32'h3000_0000, 0);
    do_read (32'h3000_0000, 0);
  endtask
endclass

// ------------- decode boundaries: range edges + unmapped --------------------
class decode_boundary_seq extends axi_base_seq;
  `uvm_object_utils(decode_boundary_seq)
  function new(string name="decode_boundary_seq"); super.new(name); endfunction
  task body();
    // last in-range word of each region (must route correctly)
    wr_then_rd(noc_pkg::S0_END - 32'h3, 0);   // 0x0FFF_FFFC -> S0
    wr_then_rd(noc_pkg::S1_BASE,        0);   // 0x1000_0000 -> S1
    wr_then_rd(noc_pkg::S1_END - 32'h3, 0);   // 0x1FFF_FFFC -> S1
    wr_then_rd(noc_pkg::P0_BASE,        0);   // 0x2000_0000 -> P0
    wr_then_rd(noc_pkg::P0_END - 32'h3, 0);   // 0x2000_FFFC -> P0
    wr_then_rd(noc_pkg::P1_BASE,        0);   // 0x2001_0000 -> P1
    wr_then_rd(noc_pkg::P1_END - 32'h3, 0);   // 0x2001_FFFC -> P1
    // just-out-of-range / unmapped (must DECERR, reach no slave)
    do_write(noc_pkg::P1_END + 32'h1, 0); do_read(noc_pkg::P1_END + 32'h1, 0); // 0x2002_0000
    do_write(32'h3000_0000, 0);           do_read(32'h3000_0000, 0);
    do_write(32'hFFFF_FFFC, 0);           do_read(32'hFFFF_FFFC, 0);
  endtask
endclass

// ------------- random traffic across all targets ----------------------------
class rand_traffic_seq extends axi_base_seq;
  `uvm_object_utils(rand_traffic_seq)
  rand int unsigned num = 40;
  function new(string name="rand_traffic_seq"); super.new(name); endfunction
  task body();
    bit [31:0] bases [4] = '{noc_pkg::S0_BASE, noc_pkg::S1_BASE, noc_pkg::P0_BASE, noc_pkg::P1_BASE};
    repeat (num) begin
      int t = $urandom_range(0,3);
      bit [31:0] off = ($urandom_range(0, 'h3F)) << 2;   // word-aligned, <256B
      int len = $urandom_range(0,3);
      bit [3:0] q = $urandom_range(0,15);
      wr_then_rd(bases[t] + off, len, q);
    end
  endtask
endclass

// ------------- storm: hammer one target (for arbitration) -------------------
class storm_seq extends axi_base_seq;
  `uvm_object_utils(storm_seq)
  rand bit [31:0] base = noc_pkg::S0_BASE;
  rand int unsigned num = 30;
  rand bit [3:0] qos = 0;
  function new(string name="storm_seq"); super.new(name); endfunction
  task body();
    repeat (num) begin
      bit [31:0] off = ($urandom_range(0,'hF)) << 2;
      do_write(base + off, 0, qos);
      do_read (base + off, 0, qos);
    end
  endtask
endclass

// ------------- virtual: both masters storm the same slave -------------------
class both_storm_vseq extends uvm_sequence;
  `uvm_object_utils(both_storm_vseq)
  `uvm_declare_p_sequencer(noc_vseqr)
  rand bit [31:0] base = noc_pkg::S0_BASE;
  rand bit [3:0]  qos0 = 0;
  rand bit [3:0]  qos1 = 0;
  function new(string name="both_storm_vseq"); super.new(name); endfunction
  task body();
    storm_seq a = storm_seq::type_id::create("a");
    storm_seq b = storm_seq::type_id::create("b");
    // Same target slave (contention at its arbiter) but DISJOINT address
    // windows so there is no cross-master same-address data hazard for the
    // golden scoreboard.  Arbitration contention is port-level, not address-level.
    a.base=base;            a.qos=qos0; a.num=40;
    b.base=base + 32'h1000; b.qos=qos1; b.num=40;
    fork
      a.start(p_sequencer.m0_seqr);
      b.start(p_sequencer.m1_seqr);
    join
  endtask
endclass

// ------------- virtual: independent mixed traffic on both masters -----------
class concurrent_mixed_vseq extends uvm_sequence;
  `uvm_object_utils(concurrent_mixed_vseq)
  `uvm_declare_p_sequencer(noc_vseqr)
  function new(string name="concurrent_mixed_vseq"); super.new(name); endfunction
  task body();
    rand_traffic_seq a = rand_traffic_seq::type_id::create("a");
    rand_traffic_seq b = rand_traffic_seq::type_id::create("b");
    a.num=50; b.num=50;
    fork
      a.start(p_sequencer.m0_seqr);
      b.start(p_sequencer.m1_seqr);
    join
  endtask
endclass
