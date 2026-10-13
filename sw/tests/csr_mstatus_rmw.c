/*
 * Phase 1.2 - atomic read-modify-write CSR instructions (csrrs/csrrc),
 * not just csrrw. Flips mstatus.MIE in isolation and checks no other
 * field moved.
 */
#include <stdint.h>
#include "../common/mmio.h"
#include "../common/csr.h"

int main(void) {
  uint32_t before = read_csr(mstatus);   /* MIE is 0 here - crt0.S never
                                           * touches mstatus, and Ibex
                                           * resets it with MIE=0. */

  uint32_t prev = set_csr_bits(mstatus, MSTATUS_MIE);   /* csrrs */
  uint32_t after_set = read_csr(mstatus);

  if (prev != before)                              { tohost = 2; for (;;) { } }
  if (!(after_set & MSTATUS_MIE))                   { tohost = 3; for (;;) { } }
  if ((after_set & ~MSTATUS_MIE) != (before & ~MSTATUS_MIE)) {
                                                       tohost = 4; for (;;) { } }

  clear_csr_bits(mstatus, MSTATUS_MIE);             /* csrrc */
  uint32_t after_clear = read_csr(mstatus);
  if (after_clear != before)                        { tohost = 5; for (;;) { } }

  tohost = 1;
  for (;;) { }
  return 0;
}
