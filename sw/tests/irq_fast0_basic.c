/*
 * irq_fast0_basic - fast line 0: bit 16 in both mie/mip and mcause, unlike
 *   the fixed 3/7/11 positions of software/timer/external.
 *
 * The C test raises its own interrupt through the irq_ctrl mailbox
 * (irqmbox.h -> ibex_driver.sv), so it runs with the plain base test:
 *   make sim TEST=irq_fast0_basic
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
  if (mcause != (MCAUSE_INT | MCAUSE_FAST(0))) {
    printf("ISR: unexpected trap, mtval=%x\n", mtval);
    test_fail(0xE0);
  }
  irq_seen = 1;
  /* Deassert before mret - the pin is level-sensitive, and mret restores
   * mstatus.MIE, so leaving it asserted would re-trap immediately. */
  irq_request(IRQ_LINE_FAST(0), 0);
  return mepc;   /* interrupts resume exactly where they interrupted */
}

int main(void) {
  print_str("irq_fast0_basic: start\n");
  set_csr_bits(mie, MIE_MFIE(0));       /* this source on */
  set_csr_bits(mstatus, MSTATUS_MIE);   /* global enable  */
  irq_request(IRQ_LINE_FAST(0), 1);
  while (!irq_seen) { }

  print_str("irq_fast0_basic: PASS\n");
  test_pass();
}
