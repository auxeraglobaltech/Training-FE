#ifndef IRQMBOX_H
#define IRQMBOX_H

#include <stdint.h>
#include "mmio.h"

/* C -> SV mailbox: writing irq_ctrl tells ibex_driver.sv (which taps the
 * data bus the same way ibex_monitor.sv taps it for tohost) to assert or
 * deassert exactly one irq_* pin, leaving all other lines untouched.
 *
 *   bit[31]   = 1 assert / 0 deassert
 *   bits[4:0] = line_id (below)
 */
#define IRQ_LINE_SOFTWARE 0u
#define IRQ_LINE_TIMER    1u
#define IRQ_LINE_EXTERNAL 2u
#define IRQ_LINE_NMI      3u
#define IRQ_LINE_FAST0    4u              /* FAST0..FAST14 = 4..18 */
#define IRQ_LINE_FAST(n)  (4u + (n))      /* n = 0..14 */

#define IRQ_CTRL_ASSERT_BIT (1u << 31)

static inline void irq_request(uint32_t line_id, int assert) {
  irq_ctrl = (assert ? IRQ_CTRL_ASSERT_BIT : 0u) | (line_id & 0x1Fu);
}

#endif /* IRQMBOX_H */
