#ifndef IRQ_CSV_H
#define IRQ_CSV_H

/* Interrupt pins driven by SV, requested from C over the C <-> SV
 * handshake (c2sv.h). Used by the sw/tests/irq_csv_*.c tests, which run
 * with the SV test class that implements these commands:
 *
 *   make sim TEST=irq_csv_single TEST_NAME=ibex_irq_csv_test
 *
 *   C call                      SV action (tb/tests/ibex_irq_csv_test.sv)
 *   --------------------------  ---------------------------------------------
 *   sv_irq_raise(line, delay)   ack C first, THEN drive the pin high `delay`
 *                               clocks later - C is already running again
 *   sv_irq_clear(line)          drive the pin low, then ack
 *   sv_irq_raise_mask(mask)     drive several pins high at once, then ack
 *
 * Line ids are the same as irqmbox.h (IRQ_LINE_*).
 *
 * Why does raise ack *before* it drives the pin? An ISR usually calls
 * sv_irq_clear(), which is itself an sv_sync(). If the interrupt fired
 * while main() was still spinning inside sv_sync() for the raise, the
 * ISR's command would overwrite SV2C_ACK and main() would wait forever
 * for its own ack. Raising only after the ack, with a delay of at least
 * IRQ_CSV_MIN_DELAY clocks, keeps the two handshakes apart.
 */

#include <stdint.h>
#include "c2sv.h"
#include "irqmbox.h"

/* Command ids - must match the localparams in ibex_irq_csv_test.sv. */
#define CMD_IRQ_RAISE       0x10u   /* arg = line | delay << 16  */
#define CMD_IRQ_CLEAR       0x11u   /* arg = line                */
#define CMD_IRQ_RAISE_MASK  0x12u   /* arg = bit n set -> line n */

#define IRQ_CSV_MIN_DELAY   20u     /* clocks; see comment above */

static inline void sv_irq_raise(uint32_t line, uint32_t delay_clks) {
  if (delay_clks < IRQ_CSV_MIN_DELAY) delay_clks = IRQ_CSV_MIN_DELAY;
  sv_sync(CMD_IRQ_RAISE, (line & 0x1Fu) | (delay_clks << 16));
}

static inline void sv_irq_clear(uint32_t line) {
  sv_sync(CMD_IRQ_CLEAR, line & 0x1Fu);
}

/* Immediate, so only call it with interrupts globally disabled
 * (mstatus.MIE = 0) - nothing can trap while main() waits for the ack. */
static inline void sv_irq_raise_mask(uint32_t line_mask) {
  sv_sync(CMD_IRQ_RAISE_MASK, line_mask);
}

#endif /* IRQ_CSV_H */
