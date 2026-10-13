/*
 * Phase 2.2 - same template as irq_timer_basic.c, software line instead
 * (mie bit 3 / mcause 3). Repeated deliberately to lock in the pattern
 * before Phase 2.4/2.5 vary it.
 */
#include <stdint.h>
#include "../common/mmio.h"
#include "../common/csr.h"
#include "../common/irqmbox.h"
#include "../common/trap.h"

static volatile int sw_irq_seen = 0;

uint32_t trap_c_handler(uint32_t mcause, uint32_t mepc, uint32_t mtval) {
  (void)mtval;
  if (mcause == (MCAUSE_INT | MCAUSE_SOFTWARE)) {
    sw_irq_seen = 1;
    irq_request(IRQ_LINE_SOFTWARE, 0);
  }
  return mepc;
}

int main(void) {
  set_csr_bits(mie, MIE_MSIE);
  set_csr_bits(mstatus, MSTATUS_MIE);

  irq_request(IRQ_LINE_SOFTWARE, 1);
  while (!sw_irq_seen) { }

  tohost = 1;
  for (;;) { }
  return 0;
}
