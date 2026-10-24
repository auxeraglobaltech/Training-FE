#ifndef MEMMAP_H
#define MEMMAP_H

/* System memory map as seen by C code. Every address here is decoded by
 * tb_top.sv (memory model) or watched on the data bus by a UVM component;
 * keep this file and those SV files in step.
 *
 *   0x0000_0000 - 0x0000_FFFF  ROM   code, rodata, .data load image
 *   0x0001_0000 - 0x0002_FFFF  RAM   tohost/irq_ctrl, .data, .bss, stack
 *       0x0001_0000            tohost       end-of-test word   (mmio.h)
 *       0x0001_0004            irq_ctrl     IRQ pin mailbox    (irqmbox.h)
 *       0x0001_5000 - 0x15FFF  SCRATCH      free for tests (link.ld guards it)
 *       0x0003_0000            _stack_top   (stack grows down from here)
 *   0x0003_0000 - 0x0003_0FFF  TB I/O page  registers implemented by the TB
 */

/* ---- Test scratch area: plain RAM, use with absolute pointers ---- */
#define SCRATCH_BASE   0x00015000u
#define SCRATCH_SIZE   0x00001000u      /* 4 KB */

/* ---- TB I/O page: not memory - each word is a TB register ---- */
#define TB_IO_BASE     0x00030000u
#define CONSOLE_TX     (TB_IO_BASE + 0x00u)  /* W: one character      (print.h) */
#define C2SV_CMD       (TB_IO_BASE + 0x10u)  /* W: command id, wakes SV (c2sv.h) */
#define C2SV_ARG       (TB_IO_BASE + 0x14u)  /* W: argument for next command   */
#define SV2C_ACK       (TB_IO_BASE + 0x18u)  /* R: = command id when SV is done */
#define SV2C_DATA      (TB_IO_BASE + 0x1Cu)  /* R: result returned by SV       */

/* Turn an address into an lvalue: REG32(addr) = v;  v = REG32(addr); */
#define REG32(addr)    (*(volatile uint32_t *)(addr))

#endif /* MEMMAP_H */
