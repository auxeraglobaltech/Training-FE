/*
 * Phase 1.4 - mcycle/minstret are free-running counters. Snapshot
 * before/after a known-length loop and check both moved by a plausible
 * amount. This is the timing idiom later interrupt-latency tests reuse.
 */
#include <stdint.h>
#include "../common/mmio.h"
#include "../common/csr.h"

int main(void) {
  uint32_t cyc_start   = read_csr(mcycle);
  uint32_t instr_start = read_csr(minstret);

  for (volatile int i = 0; i < 1000; i++) { }

  uint32_t cyc_delta   = read_csr(mcycle)   - cyc_start;
  uint32_t instr_delta = read_csr(minstret) - instr_start;

  /* Loose bounds on purpose - this proves both counters are
   * free-running and moving with real execution, not an exact match
   * against a specific pipeline's cycles-per-iteration count. */
  if (cyc_delta   < 1000) { tohost = 2; for (;;) { } }
  if (instr_delta < 1000) { tohost = 3; for (;;) { } }

  tohost = 1;
  for (;;) { }
  return 0;
}
