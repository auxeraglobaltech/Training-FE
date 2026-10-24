  .section .text.start,"ax",@progbits
  .globl _start
_start:
  # Install the trap-vector table before anything else can fault, so
  # mtvec is never left at its reset value (0x0) by accident. trap_vectors
  # is placed at a linker-enforced 256-byte boundary (see link.ld) because
  # Ibex hardwires mtvec[7:0] on every write and passes mtvec[31:8] through
  # unrounded - an unaligned target here would silently truncate the
  # effective base below the real table.
  la   t0, trap_vectors
  csrw mtvec, t0

  la   sp, _stack_top

  # Copy initialised globals (.data) from their ROM image to RAM - see
  # the .data comment in link.ld.
  la   t0, _data_lma
  la   t1, _data_start
  la   t2, _data_end
data_loop:
  bge  t1, t2, data_done
  lw   t3, 0(t0)
  sw   t3, 0(t1)
  addi t0, t0, 4
  addi t1, t1, 4
  j    data_loop
data_done:

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

  # main() returned: its return value decides the result, same encoding
  # as test_pass()/test_fail() in sw/common/test_end.h.
  #   return 0      -> tohost = 1                  (PASS)
  #   return code   -> tohost = 0xFA110000 | code  (FAIL, code = 1..0xFFFF)
  la   t0, tohost
  li   t1, 1
  beqz a0, write_tohost
  slli a0, a0, 16          # keep only the low 16 bits of the code
  srli a0, a0, 16
  li   t1, 0xFA110000
  or   t1, t1, a0
write_tohost:
  sw   t1, 0(t0)
_halt:
  j _halt

  # ---------------------------------------------------------------
  # Trap vector table (32 x 4-byte slots = 128 bytes).
  #
  # Ibex dispatches synchronous exceptions to base+0 always, and
  # interrupts to base + 4*mcause[4:0] (see ibex_if_stage.sv) - it does
  # NOT read mtvec's mode bits to decide this, so every one of the 32
  # possible cause values (0-2,5-7 synchronous; 3=sw, 7=timer,
  # 11=external, 16-30=fast0-14, 31=nmi interrupts) needs a slot that
  # lands on real code. Every slot jumps to the one shared handler below,
  # which keeps the original "single entry point" model while fixing the
  # routing.
  # ---------------------------------------------------------------
  .section .text.trap_vec,"ax",@progbits
  .option push
  .option norvc        # force 4-byte jumps - a compressed c.j would
                        # break the fixed 4-byte-per-slot spacing below
  .balign 256
  .globl trap_vectors
trap_vectors:
  .rept 32
  j trap_common
  .endr
  .option pop

  # ---------------------------------------------------------------
  # Shared trap handler for every vector slot above.
  #
  # Saves the registers an ISR body can clobber (ra, t0-t6, a0-a7) plus
  # mepc/mstatus, which must be snapshotted to the stack - not left live
  # in the CSRs - so that a *nested* trap taken from inside
  # trap_c_handler cannot overwrite this trap's own return state before
  # this handler's own mret runs.
  #
  # Dispatches to trap_c_handler(mcause, mepc, mtval), a normal C
  # function each test defines for the causes it cares about; any cause
  # not handled there falls through to the weak default below.
  #
  # trap_c_handler returns the PC execution should resume at (usually
  # just the mepc it was given, unchanged). It must NOT try to change
  # the resume address via `write_csr(mepc, ...)` - this handler always
  # restores mepc from the stack snapshot taken below, specifically so a
  # *nested* trap can't corrupt the outer handler's return address, so a
  # plain CSR write from C would be silently overwritten the moment this
  # handler resumes after the call. The return-value path below is the
  # only supported way to change it.
  # ---------------------------------------------------------------
  .section .text.trap,"ax",@progbits
  .align 2
  .globl trap_common
trap_common:
  addi sp, sp, -80
  sw   ra,  0(sp)
  sw   t0,  4(sp)
  sw   t1,  8(sp)
  sw   t2, 12(sp)
  sw   t3, 16(sp)
  sw   t4, 20(sp)
  sw   t5, 24(sp)
  sw   t6, 28(sp)
  sw   a0, 32(sp)
  sw   a1, 36(sp)
  sw   a2, 40(sp)
  sw   a3, 44(sp)
  sw   a4, 48(sp)
  sw   a5, 52(sp)
  sw   a6, 56(sp)
  sw   a7, 60(sp)

  csrr t0, mepc
  sw   t0, 64(sp)
  csrr t0, mstatus
  sw   t0, 68(sp)

  csrr a0, mcause
  csrr a1, mepc
  csrr a2, mtval
  call trap_c_handler
  sw   a0, 64(sp)        # handler's chosen resume PC overwrites the
                          # saved mepc slot - see comment above

  lw   t0, 68(sp)
  csrw mstatus, t0
  lw   t0, 64(sp)
  csrw mepc, t0

  lw   a7, 60(sp)
  lw   a6, 56(sp)
  lw   a5, 52(sp)
  lw   a4, 48(sp)
  lw   a3, 44(sp)
  lw   a2, 40(sp)
  lw   a1, 36(sp)
  lw   a0, 32(sp)
  lw   t6, 28(sp)
  lw   t5, 24(sp)
  lw   t4, 20(sp)
  lw   t3, 16(sp)
  lw   t2, 12(sp)
  lw   t1,  8(sp)
  lw   t0,  4(sp)
  lw   ra,  0(sp)
  addi sp, sp, 80
  mret

  # ---------------------------------------------------------------
  # Default trap_c_handler: forwards mcause to tohost and halts. Weak so
  # any test that defines its own trap_c_handler (strong symbol) silences
  # this one at link time; tests that never expect a trap (e.g.
  # hello_world) link against this unchanged fallback.
  # ---------------------------------------------------------------
  .section .text.trap_default,"ax",@progbits
  .weak trap_c_handler
  .type trap_c_handler, @function
trap_c_handler:
  la   t0, tohost
  sw   a0, 0(t0)
default_trap_halt:
  j default_trap_halt

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

  # tohost / irq_ctrl: NOLOAD section pinned to 0x10000 by link.ld.
  .section .tohost,"aw",@nobits
  .globl tohost
tohost: .space 4
  .globl irq_ctrl
irq_ctrl: .space 4
