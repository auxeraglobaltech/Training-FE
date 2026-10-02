  .section .text.start,"ax",@progbits
  .globl _start
_start:
  # Install the real trap handler before anything else can fault,
  # so mtvec is never left at its reset value (0x0) by accident.
  la   t0, trap_handler
  csrw mtvec, t0

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

  # ---------------------------------------------------------------
  # Trap handler: any exception or interrupt lands here (mtvec,
  # direct mode - exceptions and interrupts both vector to this one
  # entry). Forward the raw mcause CSR to tohost so the testbench
  # can report *why* the test terminated, then halt.
  # ---------------------------------------------------------------
  .section .text.trap,"ax",@progbits
  .align 2
  .globl trap_handler
trap_handler:
  csrr t2, mcause
  la   t0, tohost
  sw   t2, 0(t0)
trap_halt:
  j trap_halt

  # ---------------------------------------------------------------
  # Hardware reset vector. Ibex always fetches its first instruction
  # from boot_addr_i + 0x80; this trampoline makes that boot path
  # explicit instead of relying on an illegal-instruction trap into
  # a coincidentally-zero mtvec.
  # ---------------------------------------------------------------
  .section .text.reset_vector,"ax",@progbits
  .globl _reset_entry
_reset_entry:
  j _start

  .section .data
  .globl tohost
tohost: .word 0
