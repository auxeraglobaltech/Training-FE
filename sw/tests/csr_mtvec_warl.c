/*
 * Phase 1.3 - mtvec WARL behaviour. Ibex forces mtvec[7:0] to 0b00000001
 * on every write (hardwired vectored mode, 256-byte base alignment) and
 * passes mtvec[31:8] through unrounded - see sw/crt0.S and the Phase 0
 * trap-vector-table writeup. This test writes a deliberately misaligned
 * value and checks the readback matches that hardware rule exactly.
 */
#include <stdint.h>
#include "../common/mmio.h"
#include "../common/csr.h"

int main(void) {
  uint32_t original = read_csr(mtvec);   /* set by crt0.S to trap_vectors */

  uint32_t attempted = 0x00012345u;      /* garbage mode bits, unaligned base */
  write_csr(mtvec, attempted);
  uint32_t observed = read_csr(mtvec);
  uint32_t expected = (attempted & 0xFFFFFF00u) | 0x1u;

  if (observed != expected) { tohost = 2; for (;;) { } }

  /* Restore the real vector table before anything else could trap. */
  write_csr(mtvec, original);
  if (read_csr(mtvec) != original) { tohost = 3; for (;;) { } }

  tohost = 1;
  for (;;) { }
  return 0;
}
