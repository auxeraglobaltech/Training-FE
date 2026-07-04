// ============================================================
//  Kernel-running tests (Layer B) — thin specializations of
//  vx_base_test; the kernel image comes from the Makefile KERNEL= knob.
// ============================================================
`ifndef VX_KERNEL_TESTS_SV
`define VX_KERNEL_TESTS_SV

// asm self-checking micro-test: run with KERNEL=asm/self_check.
// PASS = crt0 magic (main returned 0); a failing check would encode
// 0xBAD0_<check-id> which the scoreboard rejects.
class vx_asm_test extends vx_base_test;
  `uvm_component_utils(vx_asm_test)
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction
endclass

// C vecadd kernel: run with KERNEL=c/vecadd. Besides the exit magic the
// scoreboard verifies the output region against +EXPECTED (golden file).
class vx_vecadd_test extends vx_base_test;
  `uvm_component_utils(vx_vecadd_test)
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction
  function void build_phase(uvm_phase phase);
    string s;
    super.build_phase(phase);
    if (!$value$plusargs("EXPECTED=%s", s))
      `uvm_warning("TEST", "vecadd without +EXPECTED= golden file")
  endfunction
endclass

`endif
