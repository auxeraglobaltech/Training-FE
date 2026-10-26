/*
 * irq_csv_multi - the same flow as irq_csv_single, repeated for several
 * interrupt lines, one at a time.
 *
 * Run:  make sim TEST=irq_csv_multi TEST_NAME=ibex_irq_csv_test
 *
 * Each line differs in three numbers that must agree with each other:
 *
 *   line       mie bit   mcause (int bit + code)   vector slot
 *   software      3      0x8000_0003               mtvec + 0x0C
 *   timer         7      0x8000_0007               mtvec + 0x1C
 *   external     11      0x8000_000B               mtvec + 0x2C
 *   fast0        16      0x8000_0010               mtvec + 0x40
 *   fast5        21      0x8000_0015               mtvec + 0x54
 *
 * For every row: enable only that mie bit, ask SV to raise the pin, wait
 * for the ISR, and check the ISR saw exactly the mcause in the table.
 */
#include <stdint.h>
#include "../common/csr.h"
#include "../common/irq_csv.h"
#include "../common/print.h"
#include "../common/trap.h"
#include "../common/test_end.h"

typedef struct {
  uint32_t line;       /* irqmbox.h id - what SV drives  */
  uint32_t mie_bit;    /* what C must enable              */
  uint32_t mcause;     /* what the ISR must see           */
} irq_case_t;

static const irq_case_t cases[] = {
  { IRQ_LINE_SOFTWARE, MIE_MSIE,    MCAUSE_INT | MCAUSE_SOFTWARE },
  { IRQ_LINE_TIMER,    MIE_MTIE,    MCAUSE_INT | MCAUSE_TIMER    },
  { IRQ_LINE_EXTERNAL, MIE_MEIE,    MCAUSE_INT | MCAUSE_EXTERNAL },
  { IRQ_LINE_FAST(0),  MIE_MFIE(0), MCAUSE_INT | MCAUSE_FAST(0)  },
  { IRQ_LINE_FAST(5),  MIE_MFIE(5), MCAUSE_INT | MCAUSE_FAST(5)  },
};
#define NUM_CASES (sizeof(cases) / sizeof(cases[0]))

static volatile uint32_t cur;          /* index of the case being run */
static volatile uint32_t seen_mcause;  /* 0 until the ISR runs        */

uint32_t trap_c_handler(uint32_t mcause, uint32_t mepc, uint32_t mtval) {
  (void)mtval;
  /* Each mcause has its own 4-byte slot in the vector table; this is
   * the slot the core jumped to before landing in trap_common. */
  uint32_t slot = (read_csr(mtvec) & ~0xFFu) + 4u * (mcause & 0x1Fu);
  printf("ISR: mcause=%x (%s) via slot %x, mepc=%x\n",
         mcause, mcause_name(mcause), slot, mepc);

  seen_mcause = mcause;
  if (mcause & MCAUSE_INT)
    sv_irq_clear(cases[cur].line);   /* drop the pin we asked for */
  return mepc;
}

int main(void) {
  print_str("irq_csv_multi: start\n");
  set_csr_bits(mstatus, MSTATUS_MIE);          /* global enable, once */

  for (uint32_t i = 0; i < NUM_CASES; i++) {
    cur = i;
    seen_mcause = 0;

    write_csr(mie, cases[i].mie_bit);          /* only this source on */
    sv_irq_raise(cases[i].line, 30);
    while (seen_mcause == 0) { }               /* wait for the ISR    */

    if (seen_mcause != cases[i].mcause) {
      printf("C : case %d expected mcause %x, got %x\n",
             i, cases[i].mcause, seen_mcause);
      test_fail(0x10 + i);
    }
  }

  write_csr(mie, 0);
  printf("irq_csv_multi: PASS, %d lines checked\n", NUM_CASES);
  test_pass();
}
