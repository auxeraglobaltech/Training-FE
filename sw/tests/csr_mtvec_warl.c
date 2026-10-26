/*
 * csr_mtvec_warl - mtvec is a WARL register (Write Any, Read Legal).
 * Ibex forces mtvec[7:0] to 0b00000001 on every write (hardwired vectored
 * mode, 256-byte base alignment) and passes mtvec[31:8] through
 * unrounded - see sw/crt0.S. This test writes a deliberately misaligned
 * value and checks the readback matches that hardware rule exactly.
 */
#include <stdint.h>
#include "../common/csr.h"
#include "../common/print.h"
#include "../common/test_end.h"

int main(void) {
  print_str("csr_mtvec_warl: start\n");

  uint32_t original = read_csr(mtvec);   /* set by crt0.S to trap_vectors */

  uint32_t attempted = 0x00012345u;      /* garbage mode bits, unaligned base */
  write_csr(mtvec, attempted);
  uint32_t observed = read_csr(mtvec);
  uint32_t expected = (attempted & 0xFFFFFF00u) | 0x1u;
  printf("  mtvec original=%x wrote=%x read=%x expected=%x\n",
         original, attempted, observed, expected);

  if (observed != expected) test_fail(2);

  /* Restore the real vector table before anything else could trap. */
  write_csr(mtvec, original);
  if (read_csr(mtvec) != original) test_fail(3);

  print_str("csr_mtvec_warl: PASS\n");
  test_pass();
}
