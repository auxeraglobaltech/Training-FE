# Vortex single-core DV — simulation area

Xcelium (xrun) build/run for the 1-core Vortex UVM environment.
Full docs: `../docs/vx_design_spec.html`, `../docs/vx_verification_plan.html`,
`../docs/vx_testcases.html` (boot/DCR quick-ref: `../docs/boot_dcr_notes.md`).

## Prerequisites
- `source ~/cshrc` (Xcelium 25.03, csh)
- Kernels built once: `make -C ../sw` (RV32 toolchain at
  `/home/user1/vortex/riscv32-gnu-toolchain`)

## Targets
```
make elab                                  # compile + elaborate only (0 errors expected)
make vx_smoke                              # directed SV smoke (asm/nop)
make sim TESTNAME=<uvm_test> KERNEL=<k>    # UVM run
make cosim KERNEL=<k>                      # replay same ELF on simx golden
make waves / make clean
```

## Knobs
| Knob | Default | Effect |
|------|---------|--------|
| `TESTNAME` | `vx_base_test` | UVM test: `vx_base_test`, `vx_asm_test`, `vx_vecadd_test` |
| `KERNEL` | `asm/nop` | `asm/nop`, `asm/self_check`, `asm/divergence`, `c/vecadd`, `c/memcpy_stride`, `c/ctrl_flow`, `c/fp_ops`; `+EXPECTED` auto-added if `<KERNEL>.expected.hex` exists |
| `HYBRID` | 0 | 1 = compile DPI-C golden (`../sw/ref/vx_ref.c`) and cross-check output region |
| `COV` | 0 | 1 = `-coverage all -covoverwrite` |
| `WAVES` | 0 | 1 = record waves (wave.tcl) |

## Pass criteria
`UVM_ERROR : 0`, no 2M-cycle watchdog; scoreboard requires exit word 0 at
0x8348, done magic 0x600DC0DE at 0x8350, and n_rd > 0 (anti-false-pass).
`make cosim` prints `COSIM: [OK]` on success.

## Filelists
- `filelist_vx.f` — RTL for the frozen 1-core config; `dv/shim/` shadow copies
  listed explicitly (before `-y` dirs — explicit entries shadow, `-y` order
  does not).
- `filelist_smoke.f` / `filelist_uvm.f` — the respective TB tops.

Tip: a stale `xcelium.d` can report ghost errors — `rm -rf xcelium.d` before
judging a surprising elaboration failure.
