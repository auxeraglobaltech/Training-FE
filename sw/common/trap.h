#ifndef TRAP_H
#define TRAP_H

#include <stdint.h>

/* Each test defines this for the causes it cares about; a weak default
 * in crt0.S (forwards mcause to tohost, halts) covers tests that don't.
 *
 * Returns the PC execution should resume at via mret - usually just
 * `mepc` unchanged. trap_common (crt0.S) writes this return value into
 * its saved-mepc stack slot before restoring the mepc CSR, so this is
 * the only supported way to change the resume address; a plain
 * `write_csr(mepc, ...)` from inside the handler gets silently
 * overwritten.
 */
uint32_t trap_c_handler(uint32_t mcause, uint32_t mepc, uint32_t mtval);

/* mcause -> readable name, for ISR prints. Bit 31 = interrupt, low bits =
 * cause code (csr.h MCAUSE_*). */
static inline const char *mcause_name(uint32_t mcause) {
  static const char *const fast[15] = {
    "fast0", "fast1", "fast2", "fast3", "fast4",  "fast5",  "fast6", "fast7",
    "fast8", "fast9", "fast10", "fast11", "fast12", "fast13", "fast14",
  };
  uint32_t code = mcause & 0x7FFFFFFFu;
  if (!(mcause & 0x80000000u)) {
    switch (code) {
      case 0:  return "instr misaligned";
      case 1:  return "instr access fault";
      case 2:  return "illegal instruction";
      case 3:  return "breakpoint";
      case 5:  return "load access fault";
      case 7:  return "store access fault";
      case 8:  return "ecall from U";
      case 11: return "ecall from M";
      default: return "exception ?";
    }
  }
  if (code == 3)                return "software";
  if (code == 7)                return "timer";
  if (code == 11)               return "external";
  if (code == 31)               return "nmi";
  if (code >= 16 && code <= 30) return fast[code - 16];
  return "interrupt ?";
}

#endif /* TRAP_H */
