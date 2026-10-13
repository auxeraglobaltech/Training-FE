/*
 * Phase 2.1 - simplest interrupt test: enable the timer line, request it
 * via the C -> SV mailbox, let the ISR observe mcause, deassert via the
 * mailbox again, and mret back here. Establishes the template every
 * other Phase 2 test repeats with a different source.
 */
#include <stdint.h>
#include "../common/mmio.h"
#include "../common/csr.h"
#include "../common/irqmbox.h"
#include "../common/trap.h"

static volatile int timer_irq_seen = 0;

uint32_t trap_c_handler(uint32_t mcause, uint32_t mepc, uint32_t mtval) {
  (void)mtval;
  if (mcause == (MCAUSE_INT | MCAUSE_TIMER)) {
    timer_irq_seen = 1;
    /* Deassert before mret - the pin is level-sensitive, and mret will
     * restore mstatus.MIE, so leaving it asserted would re-trap
     * immediately. */
    irq_request(IRQ_LINE_TIMER, 0);
  }
  return mepc;   /* interrupts resume exactly where they interrupted */
}

int main(void) {
  set_csr_bits(mie, MIE_MTIE);
  set_csr_bits(mstatus, MSTATUS_MIE);

  irq_request(IRQ_LINE_TIMER, 1);
  while (!timer_irq_seen) { }

  tohost = 1;
  for (;;) { }
  return 0;
}
