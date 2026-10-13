/*
 * Phase 1.1 - simplest possible CSR test: mscratch has no hardware side
 * effects at all, so write/read-back is a pure test of csrw/csrr.
 */
#include <stdint.h>
#include "../common/mmio.h"
#include "../common/csr.h"

static const uint32_t kPatterns[] = {
  0x00000000u, 0xFFFFFFFFu, 0xDEADBEEFu, 0x12345678u, 0xA5A5A5A5u,
};

int main(void) {
  for (unsigned i = 0; i < sizeof(kPatterns) / sizeof(kPatterns[0]); i++) {
    write_csr(mscratch, kPatterns[i]);
    uint32_t readback = read_csr(mscratch);
    if (readback != kPatterns[i]) {
      tohost = 2 + i;   /* fail code identifies which pattern mismatched */
      for (;;) { }
    }
  }

  tohost = 1;
  for (;;) { }
  return 0;
}
