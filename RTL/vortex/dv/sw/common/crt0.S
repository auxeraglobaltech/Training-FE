# Minimal Vortex DV crt0: stack in global memory, zero BSS, call main,
# publish result at VX_MEM_IO_EXIT_CODE (0x8348), retire the warp.
#   exit code (0x8348): main() return value — 0 = PASS (simx-compatible)
#   done flag (0x8350): always 0x600DC0DE — proves the kernel actually ran
#                       (unwritten memory reads back 0, which would otherwise
#                        be indistinguishable from a passing exit code)
#
# Single-hart model (grid/block = 1x1x1); no TLS, no libc.

#define EXIT_CODE_ADDR 0x8348
#define DONE_MAGIC     0x600DC0DE
#define STACK_TOP      0x80100000

.section .init, "ax"
.global _start
_start:
  li    sp, STACK_TOP
  # zero bss
  la    t0, __bss_start
  la    t1, __bss_end
1:bgeu  t0, t1, 2f
  sw    zero, 0(t0)
  addi  t0, t0, 4
  j     1b
2:
  call  main
  li    t0, EXIT_CODE_ADDR
  sw    a0, 0(t0)               # exit code: 0 = PASS
  li    t1, DONE_MAGIC
  sw    t1, 8(t0)               # done flag @0x8350
  # wsync: drain pending memory ops, then retire the warp (tmc x0)
  .insn r 0x0B, 7, 0, x0, x0, x0
  .insn r 0x0B, 0, 0, x0, x0, x0
1:j     1b
