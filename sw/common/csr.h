#ifndef CSR_H
#define CSR_H

#include <stdint.h>

/* asm volatile wrappers around the Zicsr instructions. `reg` must be a
 * bare CSR name token (mstatus, mie, mtvec, ...), not a string or macro
 * expansion, since it is pasted directly into the asm template. */

#define read_csr(reg) ({ \
  uint32_t __v; \
  asm volatile ("csrr %0, " #reg : "=r"(__v)); \
  __v; \
})

#define write_csr(reg, val) \
  asm volatile ("csrw " #reg ", %0" :: "r"((uint32_t)(val)))

/* csrrw: swaps in `val`, returns the CSR's previous value. */
#define swap_csr(reg, val) ({ \
  uint32_t __v; \
  asm volatile ("csrrw %0, " #reg ", %1" : "=r"(__v) : "r"((uint32_t)(val))); \
  __v; \
})

/* csrrs: atomically ORs `mask` into the CSR, returns the previous value. */
#define set_csr_bits(reg, mask) ({ \
  uint32_t __v; \
  asm volatile ("csrrs %0, " #reg ", %1" : "=r"(__v) : "r"((uint32_t)(mask))); \
  __v; \
})

/* csrrc: atomically clears `mask` from the CSR, returns the previous value. */
#define clear_csr_bits(reg, mask) ({ \
  uint32_t __v; \
  asm volatile ("csrrc %0, " #reg ", %1" : "=r"(__v) : "r"((uint32_t)(mask))); \
  __v; \
})

/* mstatus fields (ibex_pkg.sv: CSR_MSTATUS_*_BIT). */
#define MSTATUS_MIE       (1u << 3)
#define MSTATUS_MPIE      (1u << 7)
#define MSTATUS_MPP_SHIFT 11
#define MSTATUS_MPP_MASK  (0x3u << MSTATUS_MPP_SHIFT)
#define MSTATUS_MPP_M     (0x3u << MSTATUS_MPP_SHIFT)
#define MSTATUS_MPP_U     (0x0u << MSTATUS_MPP_SHIFT)

/* mie / mip share the same bit layout (ibex_cs_registers.sv: mip is
 * purely combinational from the irq_*_i pins, independent of mie). */
#define MIE_MSIE       (1u << 3)
#define MIE_MTIE       (1u << 7)
#define MIE_MEIE       (1u << 11)
#define MIE_MFIE(n)    (1u << (16 + (n)))   /* n = 0..14 */

/* mcause values (ibex_pkg.sv: ExcCauseIrq*, ExcCauseIllegalInsn, ...). */
#define MCAUSE_INT         (1u << 31)
#define MCAUSE_ILLEGAL_INSN 2u
#define MCAUSE_SOFTWARE    3u
#define MCAUSE_TIMER       7u
#define MCAUSE_EXTERNAL    11u
#define MCAUSE_FAST(n)     (16u + (n))      /* n = 0..14 */
#define MCAUSE_NMI         31u

#endif /* CSR_H */
