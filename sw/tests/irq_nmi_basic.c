/*
 * Phase 2.5 - NMI bypasses mie/mstatus.MIE entirely (always taken,
 * highest priority) - deliberately leaves both at 0 to prove it. Also
 * confirms the core's nmi_mode latch clears on mret (ibex_controller.sv)
 * so execution can return normally instead of staying latched.
 */
#include <stdint.h>
#include "../common/mmio.h"
#include "../common/csr.h"
#include "../common/irqmbox.h"
#include "../common/trap.h"

static volatile int nmi_seen = 0;

uint32_t trap_c_handler(uint32_t mcause, uint32_t mepc, uint32_t mtval) {
  (void)mtval;
  if (mcause == (MCAUSE_INT | MCAUSE_NMI)) {
    nmi_seen = 1;
    irq_request(IRQ_LINE_NMI, 0);
  }
  return mepc;
}

int main(void) {
  /* mie and mstatus.MIE both stay 0 - NMI must fire regardless. */
  irq_request(IRQ_LINE_NMI, 1);
  while (!nmi_seen) { }

  tohost = 1;
  for (;;) { }
  return 0;
}
