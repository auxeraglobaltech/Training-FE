/*
 * irq_csv_single - one interrupt, end to end, with C <-> SV communication.
 *
 * Run:  make sim TEST=irq_csv_single TEST_NAME=ibex_irq_csv_test
 *
 *   1. C  configures the core: mie.MEIE = 1, mstatus.MIE = 1
 *   2. C  asks SV to raise irq_external in 200 clocks  (sv_irq_raise)
 *   3. C  keeps computing a Fibonacci sequence in registers
 *   4. HW pin goes high -> core saves PC in mepc, jumps to trap_vectors +
 *         4*11, trap_common (crt0.S) saves registers, calls trap_c_handler
 *   5. ISR prints mcause/mepc/mstatus, wipes every caller-saved register,
 *         asks SV to drop the pin (sv_irq_clear), returns mepc
 *   6. trap_common restores the registers, mret -> back into the loop
 *   7. C  re-computes the sequence without interrupts and compares: if the
 *         ISR had damaged any register the loop was using, they differ
 */
#include <stdint.h>
#include "../common/csr.h"
#include "../common/irq_csv.h"
#include "../common/print.h"
#include "../common/trap.h"
#include "../common/test_end.h"

static volatile uint32_t irq_count;      /* written by ISR, read by main  */
static volatile uint32_t isr_mstatus;    /* mstatus as seen inside the ISR */

uint32_t trap_c_handler(uint32_t mcause, uint32_t mepc, uint32_t mtval) {
  if (mcause != (MCAUSE_INT | MCAUSE_EXTERNAL)) {
    printf("ISR: unexpected mcause=%x (%s) mepc=%x mtval=%x\n",
           mcause, mcause_name(mcause), mepc, mtval);
    test_fail(0xE0);
  }

  isr_mstatus = read_csr(mstatus);
  printf("ISR: mcause=%x (%s), mepc=%x\n", mcause, mcause_name(mcause), mepc);
  printf("ISR: mstatus=%x  MIE=%d MPIE=%d\n", isr_mstatus,
         (isr_mstatus & MSTATUS_MIE) != 0, (isr_mstatus & MSTATUS_MPIE) != 0);

  /* Deliberately destroy every caller-saved register. The interrupted
   * loop may have had live values in any of them; only trap_common's
   * save/restore in crt0.S protects them. */
  asm volatile ("li t0,-1; li t1,-1; li t2,-1; li t3,-1; li t4,-1; li t5,-1;"
                "li t6,-1; li a3,-1; li a4,-1; li a5,-1; li a6,-1; li a7,-1"
                ::: "t0", "t1", "t2", "t3", "t4", "t5", "t6",
                    "a3", "a4", "a5", "a6", "a7");

  /* The pin is level-sensitive: drop it before mret re-enables MIE, or
   * the same interrupt is taken again immediately. */
  sv_irq_clear(IRQ_LINE_EXTERNAL);
  irq_count++;
  return mepc;            /* an interrupt resumes exactly where it hit */
}

int main(void) {
  print_str("irq_csv_single: start\n");

  /* ---- 1. configure: enable this source, then enable globally ------- */
  set_csr_bits(mie, MIE_MEIE);
  set_csr_bits(mstatus, MSTATUS_MIE);

  /* ---- 2. ask SV for the interrupt; SV acks at once, pin rises later */
  /* Print first: a print still running when the ISR fires would get the
   * ISR's text spliced into the middle of its line in the log. */
  print_str("C : asking SV for irq_external in 200 clocks, computing meanwhile\n");
  sv_irq_raise(IRQ_LINE_EXTERNAL, 200);

  /* ---- 3. real work, in registers, until the ISR has run ------------ */
  uint32_t a = 0, b = 1, n = 0;
  while (irq_count == 0) {
    uint32_t t = a + b;
    a = b;
    b = t;
    n++;
  }

  /* ---- 7. check the work survived the interrupt --------------------- */
  clear_csr_bits(mstatus, MSTATUS_MIE);
  uint32_t ra = 0, rb = 1;
  for (uint32_t i = 0; i < n; i++) {
    uint32_t t = ra + rb;
    ra = rb;
    rb = t;
  }
  printf("C : back in main after %d loop iterations, fib a=%x b=%x\n", n, a, b);

  if (a != ra || b != rb)                    test_fail(1);  /* context lost  */
  if (irq_count != 1)                        test_fail(2);  /* taken != once */
  if (isr_mstatus & MSTATUS_MIE)             test_fail(3);  /* HW clears MIE */
  if (!(isr_mstatus & MSTATUS_MPIE))         test_fail(4);  /* ...saves MPIE */
  if (!(read_csr(mstatus) & MSTATUS_MPIE))   test_fail(5);  /* mret sets MPIE */

  print_str("irq_csv_single: PASS\n");
  test_pass();
}
