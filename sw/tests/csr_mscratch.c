/*
 * csr_mscratch - simplest possible CSR test: mscratch has no hardware
 * side effects at all, so write/read-back is a pure test of csrw/csrr.
 */
#include <stdint.h>
#include "../common/csr.h"
#include "../common/print.h"
#include "../common/test_end.h"

static const uint32_t kPatterns[] = {
  0x00000000u, 0xFFFFFFFFu, 0xDEADBEEFu, 0x12345678u, 0xA5A5A5A5u,
};

int main(void) {
  print_str("csr_mscratch: start\n");

  for (unsigned i = 0; i < sizeof(kPatterns) / sizeof(kPatterns[0]); i++) {
    write_csr(mscratch, kPatterns[i]);           /* csrw mscratch, rs */
    uint32_t readback = read_csr(mscratch);      /* csrr rd, mscratch */
    printf("  mscratch wrote %x read %x\n", kPatterns[i], readback);
    if (readback != kPatterns[i])
      test_fail(2 + i);   /* fail code identifies which pattern mismatched */
  }

  print_str("csr_mscratch: PASS\n");
  test_pass();
}
