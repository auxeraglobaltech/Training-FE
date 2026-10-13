/*
 * Phase 0 proof test: confirms the rewritten trap vector table routes a
 * real synchronous exception to trap_common correctly, and that
 * trap_common's save/dispatch/restore path can actually resume
 * execution afterwards (not just "trap and die", which is all the old
 * single-entry trap_handler could ever do).
 */
#include <stdint.h>
#include "../common/mmio.h"
#include "../common/csr.h"
#include "../common/trap.h"

static volatile int illegal_insn_seen = 0;

uint32_t trap_c_handler(uint32_t mcause, uint32_t mepc, uint32_t mtval) {
  (void)mtval;
  illegal_insn_seen = (mcause == MCAUSE_ILLEGAL_INSN) ? 1 : 0;
  /* Skip the 4-byte illegal instruction so mret resumes right after it
   * instead of re-trapping immediately. */
  return mepc + 4;
}

int main(void) {
  asm volatile (".word 0x00000000");  /* illegal instruction -> mcause=2 */

  tohost = illegal_insn_seen ? 1 : 2;
  for (;;) { }
  return 0;
}
