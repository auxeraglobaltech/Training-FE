/*
 * irq_nmi_basic - NMI ignores mie and mstatus.MIE (always taken, highest
 *   priority), so both deliberately stay 0. Also proves the core's
 *   nmi_mode latch clears on mret (ibex_controller.sv).
 *
 * The C test raises its own interrupt through the irq_ctrl mailbox
 * (irqmbox.h -> ibex_driver.sv), so it runs with the plain base test:
 *   make sim TEST=irq_nmi_basic
 * Compare with sw/tests/irq_csv_*.c, where SV raises the pin on C's
 * request over the C <-> SV handshake instead.
 */
#include <stdint.h>
#include "../common/csr.h"
#include "../common/irqmbox.h"
#include "../common/print.h"
#include "../common/trap.h"
#include "../common/test_end.h"

static volatile int irq_seen = 0;

uint32_t trap_c_handler(uint32_t mcause, uint32_t mepc, uint32_t mtval) {
  printf("ISR: mcause=%x (%s) mepc=%x\n", mcause, mcause_name(mcause), mepc);
  if (mcause != (MCAUSE_INT | MCAUSE_NMI)) {
    printf("ISR: unexpected trap, mtval=%x\n", mtval);
    test_fail(0xE0);
  }
  irq_seen = 1;
  /* Deassert before mret - mret clears the core's nmi_mode latch, and a
   * pin still high would be taken as a new NMI immediately. */
  irq_request(IRQ_LINE_NMI, 0);
  return mepc;   /* interrupts resume exactly where they interrupted */
}

int main(void) {
  print_str("irq_nmi_basic: start\n");
  /* mie and mstatus.MIE both stay 0 - NMI must fire regardless. */
  irq_request(IRQ_LINE_NMI, 1);
  while (!irq_seen) { }

  print_str("irq_nmi_basic: PASS\n");
  test_pass();
}
