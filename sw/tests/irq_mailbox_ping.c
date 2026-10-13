/*
 * Phase 0 proof test: confirms the C -> SV irq_ctrl mailbox actually
 * reaches ibex_driver.sv and that the driven pin is visible in the
 * core's own mip CSR - in isolation from trap-taking, since mie stays 0
 * (set by crt0.S) the whole time, so no trap can fire here at all.
 */
#include <stdint.h>
#include "../common/mmio.h"
#include "../common/csr.h"
#include "../common/irqmbox.h"

int main(void) {
  irq_request(IRQ_LINE_TIMER, 1);
  while (!(read_csr(mip) & MIE_MTIE)) { }

  irq_request(IRQ_LINE_TIMER, 0);
  while (read_csr(mip) & MIE_MTIE) { }

  tohost = 1;
  for (;;) { }
  return 0;
}
