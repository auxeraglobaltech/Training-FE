/*
 * csr_mstatus_rmw - atomic read-modify-write CSR instructions (csrrs /
 * csrrc), not just csrrw. Flips mstatus.MIE in isolation and checks no
 * other field moved.
 */
#include <stdint.h>
#include "../common/csr.h"
#include "../common/print.h"
#include "../common/test_end.h"

int main(void) {
  print_str("csr_mstatus_rmw: start\n");

  /* MIE is 0 here - crt0.S never touches mstatus, and Ibex resets it
   * with MIE = 0. */
  uint32_t before = read_csr(mstatus);

  uint32_t prev      = set_csr_bits(mstatus, MSTATUS_MIE);   /* csrrs */
  uint32_t after_set = read_csr(mstatus);
  printf("  before=%x  csrrs returned=%x  after set=%x\n", before, prev, after_set);

  if (prev != before)                                         test_fail(2);
  if (!(after_set & MSTATUS_MIE))                             test_fail(3);
  if ((after_set & ~MSTATUS_MIE) != (before & ~MSTATUS_MIE))  test_fail(4);

  clear_csr_bits(mstatus, MSTATUS_MIE);                      /* csrrc */
  uint32_t after_clear = read_csr(mstatus);
  printf("  after clear=%x\n", after_clear);
  if (after_clear != before)                                  test_fail(5);

  print_str("csr_mstatus_rmw: PASS\n");
  test_pass();
}
