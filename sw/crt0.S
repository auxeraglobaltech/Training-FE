  .section .text.start,"ax",@progbits
  .globl _start
_start:
  la   sp, _stack_top
  la   t0, _bss_start
  la   t1, _bss_end
bss_loop:
  bge  t0, t1, bss_done
  sw   zero, 0(t0)
  addi t0, t0, 4
  j    bss_loop
bss_done:
  li   t0, 0
  csrw mie, t0
  call main
  la   t0, tohost
  li   t1, 1
  sw   t1, 0(t0)
_halt:
  j _halt

  .section .data
  .globl tohost
tohost: .word 0
