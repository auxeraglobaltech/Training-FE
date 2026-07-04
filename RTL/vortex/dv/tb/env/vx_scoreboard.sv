// ============================================================
//  Scoreboard (Phase 3 form): watches memory write traffic for the
//  exit-code word (VX_MEM_IO_EXIT_CODE = 0x8348) and checks it against
//  the expected value. Phase 4 adds output-region data checking;
//  Phase 5 adds DPI-C reference / simx co-sim.
// ============================================================
`ifndef VX_SCOREBOARD_SV
`define VX_SCOREBOARD_SV

`ifdef VX_HYBRID
// host-side C golden model (dv/sw/ref/vx_ref.c, compiled by xrun HYBRID=1)
import "DPI-C" function int vx_ref_num_words(input string test);
import "DPI-C" function int unsigned vx_ref_word(input string test, input int i);
`endif

class vx_scoreboard extends uvm_component;
  `uvm_component_utils(vx_scoreboard)

  uvm_analysis_imp #(vx_mem_txn, vx_scoreboard) mem_imp;

  vx_mem_model     model;
  bit [31:0]       expected_exit = 32'h0;              // 0 = PASS (simx-compatible)
  bit              exit_seen = 0;
  bit [31:0]       exit_val;
  longint unsigned n_txn = 0;

  localparam longint unsigned EXIT_ADDR  = 64'h8348;
  localparam longint unsigned DONE_ADDR  = 64'h8350;   // crt0 done flag
  localparam bit [31:0]       DONE_MAGIC = 32'h600D_C0DE;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    mem_imp = new("mem_imp", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(vx_mem_model)::get(this, "", "mem_model", model))
      `uvm_fatal("SB", "no mem_model")
    void'(uvm_config_db#(bit [31:0])::get(this, "", "expected_exit",
                                          expected_exit));
  endfunction

  function void write(vx_mem_txn t);
    n_txn++;
    // exit-code word lives inside one 64-byte line; catch the write live
    if (t.rw && (EXIT_ADDR >= t.byte_addr)
             && (EXIT_ADDR < t.byte_addr + `VX_MEM_DATA_SIZE)) begin
      int off = int'(EXIT_ADDR - t.byte_addr);
      if (t.byteen[off]) begin
        for (int i = 0; i < 4; i++)
          exit_val[i*8 +: 8] = t.data[(off+i)*8 +: 8];
        exit_seen = 1;
        `uvm_info("SB", $sformatf("exit-code write observed: 0x%08h",
                                  exit_val), UVM_LOW)
      end
    end
  endfunction

  // optional golden output-region check: +EXPECTED=<file> with
  // "<byte_addr_hex> <word_hex>" per line (e.g. vecadd.expected.hex)
  function void check_expected_file();
    string path;
    int fd, n_ok = 0, n_bad = 0;
    longint unsigned addr;
    bit [31:0] exp_val, got;
    if (!$value$plusargs("EXPECTED=%s", path)) return;
    fd = $fopen(path, "r");
    if (fd == 0) begin
      `uvm_error("SB", {"cannot open +EXPECTED file: ", path})
      return;
    end
    while ($fscanf(fd, "%h %h", addr, exp_val) == 2) begin
      got = model.rd_word(addr);
      if (got !== exp_val) begin
        n_bad++;
        `uvm_error("SB", $sformatf(
          "output mismatch @0x%08h: got 0x%08h expect 0x%08h",
          addr, got, exp_val))
      end else n_ok++;
    end
    $fclose(fd);
    if (n_bad == 0)
      `uvm_info("SB", $sformatf(
        "RESULT: output-region check PASSED (%0d words)", n_ok), UVM_LOW)
  endfunction

  // hybrid check: +REF=<test> -> recompute the output region with the
  // DPI-C golden model and compare word-by-word (base OUT = 0x80020000)
  function void check_dpi_ref();
`ifdef VX_HYBRID
    string ref_name;
    int n, n_bad = 0;
    localparam longint unsigned OUT_ADDR = 64'h8002_0000;
    if (!$value$plusargs("REF=%s", ref_name)) return;
    n = vx_ref_num_words(ref_name);
    if (n == 0) begin
      `uvm_info("SB", {"no DPI golden model for '", ref_name,
                       "' - skipping hybrid check"}, UVM_LOW)
      return;
    end
    for (int i = 0; i < n; i++) begin
      bit [31:0] exp_val = vx_ref_word(ref_name, i);
      bit [31:0] got     = model.rd_word(OUT_ADDR + 4*i);
      if (got !== exp_val) begin
        n_bad++;
        `uvm_error("SB", $sformatf(
          "DPI-ref mismatch [%s] word %0d @0x%08h: got 0x%08h expect 0x%08h",
          ref_name, i, OUT_ADDR + 4*i, got, exp_val))
      end
    end
    if (n_bad == 0)
      `uvm_info("SB", $sformatf(
        "RESULT: DPI-C reference check PASSED (%s, %0d words)",
        ref_name, n), UVM_LOW)
`endif
  endfunction

  function void check_phase(uvm_phase phase);
    bit [31:0] done_val = model.rd_word(DONE_ADDR);
    bit [31:0] mem_val  = model.rd_word(EXIT_ADDR);
    `uvm_info("SB", $sformatf(
      "SCOREBOARD: txns=%0d reads=%0d writes=%0d exit(mem)=0x%08h",
      n_txn, model.n_rd, model.n_wr, mem_val), UVM_LOW)
    if (model.n_rd == 0)
      `uvm_error("SB", "core issued no memory reads - kernel never fetched")
    if (done_val !== DONE_MAGIC)
      `uvm_error("SB", $sformatf(
        "done flag not set: got 0x%08h expect 0x%08h - kernel never completed",
        done_val, DONE_MAGIC))
    if (!exit_seen)
      `uvm_error("SB", "no exit-code write observed on the memory bus")
    else if (mem_val !== expected_exit)
      `uvm_error("SB", $sformatf("exit-code mismatch: got 0x%08h expect 0x%08h",
                                 mem_val, expected_exit))
    else
      `uvm_info("SB", "RESULT: exit-code check PASSED", UVM_LOW)
    check_expected_file();
    check_dpi_ref();
  endfunction
endclass

`endif
