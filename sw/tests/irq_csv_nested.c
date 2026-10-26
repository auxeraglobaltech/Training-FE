/*
 * irq_csv_nested - a high-priority interrupt pre-empts a running ISR.
 *
 * Run:  make sim TEST=irq_csv_nested TEST_NAME=ibex_irq_csv_test
 *
 * On entry to any trap the core clears mstatus.MIE, so ISRs normally run
 * with interrupts off. To allow nesting, the ISR turns MIE back on itself.
 *
 *   main          timer ISR (depth 1)             fast0 ISR (depth 2)
 *   ----------    -----------------------------   --------------------
 *   enable mie
 *   raise timer
 *   spin ------>  clear timer pin
 *                 ask SV: raise fast0
 *                 mstatus.MIE = 1   (nesting on)
 *                 spin ---------------------->    clear fast0 pin
 *                                                 return (mret)
 *                 <---------------------------
 *                 mstatus.MIE = 0
 *                 return (mret)
 *   <----------
 *   check order: T-enter, F-enter, F-exit, T-exit
 *
 * Nesting is only safe because trap_common (crt0.S) saves mepc and
 * mstatus on the stack: the inner trap overwrites the mepc/mstatus CSRs,
 * and the outer ISR gets its own copies back from its stack frame.
 */
#include <stdint.h>
#include "../common/csr.h"
#include "../common/irq_csv.h"
#include "../common/print.h"
#include "../common/trap.h"
#include "../common/test_end.h"

/* Event log: who entered/left, in order. */
enum { T_ENTER = 1, T_EXIT, F_ENTER, F_EXIT };
static volatile uint32_t events[8];
static volatile uint32_t n_events;
static volatile uint32_t depth;
static volatile uint32_t fast_done;
static volatile uint32_t timer_done;

static void log_event(uint32_t e) {
  if (n_events < 8) events[n_events] = e;
  n_events++;
}

static void timer_isr(uint32_t mepc) {
  log_event(T_ENTER);
  printf("ISR timer (depth %d): enter, mepc=%x (in main)\n", depth, mepc);
  sv_irq_clear(IRQ_LINE_TIMER);

  sv_irq_raise(IRQ_LINE_FAST(0), 30);          /* higher priority, soon  */
  set_csr_bits(mstatus, MSTATUS_MIE);          /* allow nesting          */
  while (!fast_done) { }                       /* fast0 pre-empts here   */
  clear_csr_bits(mstatus, MSTATUS_MIE);        /* off again before exit  */

  printf("ISR timer (depth %d): exit\n", depth);
  log_event(T_EXIT);
  timer_done = 1;
}

static void fast0_isr(uint32_t mepc) {
  log_event(F_ENTER);
  printf("ISR fast0 (depth %d): enter, mepc=%x (inside timer ISR)\n", depth, mepc);
  sv_irq_clear(IRQ_LINE_FAST(0));
  printf("ISR fast0 (depth %d): exit\n", depth);
  log_event(F_EXIT);
  fast_done = 1;
}

uint32_t trap_c_handler(uint32_t mcause, uint32_t mepc, uint32_t mtval) {
  depth++;
  if (mcause == (MCAUSE_INT | MCAUSE_TIMER))        timer_isr(mepc);
  else if (mcause == (MCAUSE_INT | MCAUSE_FAST(0))) fast0_isr(mepc);
  else {
    printf("ISR: unexpected mcause=%x (%s) mtval=%x\n",
           mcause, mcause_name(mcause), mtval);
    test_fail(0xE0);
  }
  depth--;
  return mepc;
}

int main(void) {
  print_str("irq_csv_nested: start\n");

  write_csr(mie, MIE_MTIE | MIE_MFIE(0));
  set_csr_bits(mstatus, MSTATUS_MIE);

  sv_irq_raise(IRQ_LINE_TIMER, 30);
  while (!timer_done) { }
  clear_csr_bits(mstatus, MSTATUS_MIE);

  static const uint32_t expect[4] = { T_ENTER, F_ENTER, F_EXIT, T_EXIT };
  if (n_events != 4) test_fail(1);
  for (uint32_t i = 0; i < 4; i++)
    if (events[i] != expect[i]) test_fail(0x10 + i);
  if (depth != 0) test_fail(2);

  print_str("irq_csv_nested: PASS, timer -> fast0 -> fast0 done -> timer done\n");
  test_pass();
}
