/*
 * Phase 2.4 - introduces the fast-line bit-16 offset: fast0 sits at bit
 * 16 in both mie/mip and mcause, unlike the fixed 3/7/11 bit positions
 * of software/timer/external.
 */
#include <stdint.h>
#include "../common/mmio.h"
#include "../common/csr.h"
#include "../common/irqmbox.h"
#include "../common/trap.h"

static volatile int fast0_irq_seen = 0;

uint32_t trap_c_handler(uint32_t mcause, uint32_t mepc, uint32_t mtval) {
  (void)mtval;
  if (mcause == (MCAUSE_INT | MCAUSE_FAST(0))) {
    fast0_irq_seen = 1;
    irq_request(IRQ_LINE_FAST(0), 0);
  }
  return mepc;
}

int main(void) {
  set_csr_bits(mie, MIE_MFIE(0));
  set_csr_bits(mstatus, MSTATUS_MIE);

  irq_request(IRQ_LINE_FAST(0), 1);
  while (!fast0_irq_seen) { }

  tohost = 1;
  for (;;) { }
  return 0;
}
