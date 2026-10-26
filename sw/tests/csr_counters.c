/*
 * csr_counters - mcycle/minstret are free-running counters. Snapshot
 * before/after a known-length loop and check both moved by a plausible
 * amount. This is the timing idiom later interrupt-latency tests reuse.
 */
#include <stdint.h>
#include "../common/csr.h"
#include "../common/print.h"
#include "../common/test_end.h"

int main(void) {
  print_str("csr_counters: start\n");

  uint32_t cyc_start   = read_csr(mcycle);
  uint32_t instr_start = read_csr(minstret);

  for (volatile int i = 0; i < 1000; i++) { }

  uint32_t cyc_delta   = read_csr(mcycle)   - cyc_start;
  uint32_t instr_delta = read_csr(minstret) - instr_start;
  printf("  1000-iteration loop: %d cycles, %d instructions retired\n",
         cyc_delta, instr_delta);

  /* Loose bounds on purpose - this proves both counters are
   * free-running and moving with real execution, not an exact match
   * against a specific pipeline's cycles-per-iteration count. */
  if (cyc_delta   < 1000) test_fail(2);
  if (instr_delta < 1000) test_fail(3);

  print_str("csr_counters: PASS\n");
  test_pass();
}
