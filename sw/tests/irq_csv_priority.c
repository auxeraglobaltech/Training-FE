/*
 * irq_csv_priority - several interrupts pending at the same moment: which
 * one does the core take first?
 *
 * Run:  make sim TEST=irq_csv_priority TEST_NAME=ibex_irq_csv_test
 *
 * Ibex priority (ibex_controller.sv), highest first:
 *
 *   NMI  >  fast0 > fast1 > ... > fast14  >  external  >  software  >  timer
 *
 * Note this differs from the plain RISC-V privileged spec order
 * (external > software > timer), because Ibex puts its fast lines on top.
 *
 *   1. C  enables five sources in mie, but keeps mstatus.MIE = 0
 *   2. C  asks SV to raise all five pins at once  -> all pending, none taken
 *   3. C  sets mstatus.MIE = 1                    -> the core now takes them
 *         one after another, highest priority first; each ISR records its
 *         mcause and asks SV to drop that one pin
 *   4. C  checks the recorded order
 */
#include <stdint.h>
#include "../common/csr.h"
#include "../common/irq_csv.h"
#include "../common/print.h"
#include "../common/trap.h"
#include "../common/test_end.h"

#define NUM_IRQS 5

/* Expected order of service, highest priority first. */
static const uint32_t expected[NUM_IRQS] = {
  MCAUSE_INT | MCAUSE_FAST(0),
  MCAUSE_INT | MCAUSE_FAST(1),
  MCAUSE_INT | MCAUSE_EXTERNAL,
  MCAUSE_INT | MCAUSE_SOFTWARE,
  MCAUSE_INT | MCAUSE_TIMER,
};

static volatile uint32_t order[NUM_IRQS];   /* mcause in service order */
static volatile uint32_t taken;

/* mcause -> the irqmbox.h line id SV must drop. */
static uint32_t line_of(uint32_t mcause) {
  uint32_t code = mcause & 0x1Fu;
  if (code == MCAUSE_SOFTWARE) return IRQ_LINE_SOFTWARE;
  if (code == MCAUSE_TIMER)    return IRQ_LINE_TIMER;
  if (code == MCAUSE_EXTERNAL) return IRQ_LINE_EXTERNAL;
  return IRQ_LINE_FAST(code - 16u);
}

uint32_t trap_c_handler(uint32_t mcause, uint32_t mepc, uint32_t mtval) {
  (void)mtval;
  printf("ISR #%d: mcause=%x (%s), still pending mip=%x\n",
         taken + 1, mcause, mcause_name(mcause), read_csr(mip));
  if (taken < NUM_IRQS) order[taken] = mcause;
  taken++;
  sv_irq_clear(line_of(mcause));
  return mepc;     /* mret re-enables MIE -> next pending one is taken */
}

int main(void) {
  print_str("irq_csv_priority: start\n");

  /* ---- 1. enable sources, but not globally -------------------------- */
  write_csr(mie, MIE_MSIE | MIE_MTIE | MIE_MEIE | MIE_MFIE(0) | MIE_MFIE(1));

  /* ---- 2. all five pins high at once (safe: MIE = 0) ---------------- */
  sv_irq_raise_mask((1u << IRQ_LINE_SOFTWARE) | (1u << IRQ_LINE_TIMER) |
                    (1u << IRQ_LINE_EXTERNAL) | (1u << IRQ_LINE_FAST(0)) |
                    (1u << IRQ_LINE_FAST(1)));
  printf("C : all five pending, mip=%x, nothing taken yet (taken=%d)\n",
         read_csr(mip), taken);
  if (taken != 0) test_fail(1);

  /* ---- 3. open the gate --------------------------------------------- */
  set_csr_bits(mstatus, MSTATUS_MIE);
  while (taken < NUM_IRQS) { }
  clear_csr_bits(mstatus, MSTATUS_MIE);

  /* ---- 4. check the order ------------------------------------------- */
  for (uint32_t i = 0; i < NUM_IRQS; i++) {
    if (order[i] != expected[i]) {
      printf("C : position %d expected %s, got %s\n", i,
             mcause_name(expected[i]), mcause_name(order[i]));
      test_fail(0x10 + i);
    }
  }
  if (read_csr(mip) != 0) test_fail(2);   /* every pin dropped again */

  print_str("irq_csv_priority: PASS, order fast0 fast1 external software timer\n");
  test_pass();
}
