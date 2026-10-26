/*
 * irq_mailbox_ping - the C -> SV irq_ctrl mailbox reaches ibex_driver.sv
 * and the driven pin is visible in the core's own mip CSR - in isolation
 * from trap-taking: mie stays 0 (set by crt0.S) the whole time, so no
 * trap can fire here at all.
 */
#include <stdint.h>
#include "../common/csr.h"
#include "../common/irqmbox.h"
#include "../common/print.h"
#include "../common/test_end.h"

int main(void) {
  print_str("irq_mailbox_ping: start\n");

  irq_request(IRQ_LINE_TIMER, 1);
  while (!(read_csr(mip) & MIE_MTIE)) { }
  printf("  timer pin high, mip=%x\n", read_csr(mip));

  irq_request(IRQ_LINE_TIMER, 0);
  while (read_csr(mip) & MIE_MTIE) { }
  printf("  timer pin low,  mip=%x\n", read_csr(mip));

  print_str("irq_mailbox_ping: PASS\n");
  test_pass();
}
