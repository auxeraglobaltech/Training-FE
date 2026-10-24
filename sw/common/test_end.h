#ifndef TEST_END_H
#define TEST_END_H

/* How a C test ends. Every test finishes by writing tohost (0x10000)
 * exactly once; the TB sees that store, the scoreboard decodes it, and
 * tb_top ends the simulation 100 ns later.
 *
 *   tohost value            meaning                     who writes it
 *   ----------------------  --------------------------  -----------------------
 *   0x0000_0001             PASS                        test_pass() / return 0
 *   0xFA11_0000 | code      FAIL, test's own code       test_fail() / return code
 *   anything else           FAIL, unexpected trap       default trap handler
 *                           (value = mcause)            (crt0.S)
 *   (never written)         FAIL, TIMEOUT               base test watchdog
 *
 * Either call these, or just return from main(): crt0.S applies the same
 * encoding to main's return value (0 = pass, non-zero = fail code).
 */

#include <stdint.h>
#include "mmio.h"

#define TOHOST_PASS       0x00000001u
#define TOHOST_FAIL_TAG   0xFA110000u   /* upper 16 bits mark a C-reported fail */

static inline void __attribute__((noreturn)) test_pass(void) {
  tohost = TOHOST_PASS;
  for (;;) { }
}

/* code: 1..0xFFFF, pick a distinct value per check so the log tells you
 * which check failed. */
static inline void __attribute__((noreturn)) test_fail(uint32_t code) {
  tohost = TOHOST_FAIL_TAG | (code & 0xFFFFu);
  for (;;) { }
}

#endif /* TEST_END_H */
