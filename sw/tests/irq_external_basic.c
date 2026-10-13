/*
 * Phase 2.3 - same template, external line (mie bit 11 / mcause 11).
 */
#include <stdint.h>
#include "../common/mmio.h"
#include "../common/csr.h"
#include "../common/irqmbox.h"
#include "../common/trap.h"

static volatile int ext_irq_seen = 0;

uint32_t trap_c_handler(uint32_t mcause, uint32_t mepc, uint32_t mtval) {
  (void)mtval;
  if (mcause == (MCAUSE_INT | MCAUSE_EXTERNAL)) {
    ext_irq_seen = 1;
    irq_request(IRQ_LINE_EXTERNAL, 0);
  }
  return mepc;
}

int main(void) {
  set_csr_bits(mie, MIE_MEIE);
  set_csr_bits(mstatus, MSTATUS_MIE);

  irq_request(IRQ_LINE_EXTERNAL, 1);
  while (!ext_irq_seen) { }

  tohost = 1;
  for (;;) { }
  return 0;
}
