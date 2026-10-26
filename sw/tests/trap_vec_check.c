/*
 * trap_vec_check - a synchronous exception (illegal instruction) goes
 * through the trap vector table to trap_common, and trap_common's
 * save / dispatch / restore path resumes execution afterwards.
 *
 * Exceptions differ from interrupts in one important way: mepc points AT
 * the faulting instruction, so returning mepc unchanged would execute it
 * again and trap forever. The handler returns mepc + 4 to skip it.
 */
#include <stdint.h>
#include "../common/csr.h"
#include "../common/print.h"
#include "../common/trap.h"
#include "../common/test_end.h"

static volatile int illegal_insn_seen = 0;

uint32_t trap_c_handler(uint32_t mcause, uint32_t mepc, uint32_t mtval) {
  printf("TRAP: mcause=%x (%s) mepc=%x mtval=%x\n",
         mcause, mcause_name(mcause), mepc, mtval);
  illegal_insn_seen = (mcause == MCAUSE_ILLEGAL_INSN) ? 1 : 0;
  /* Skip the 4-byte illegal instruction so mret resumes right after it
   * instead of re-trapping immediately. */
  return mepc + 4;
}

int main(void) {
  print_str("trap_vec_check: executing an illegal instruction\n");
  asm volatile (".word 0x00000000");  /* illegal instruction -> mcause=2 */
  print_str("trap_vec_check: resumed after the trap\n");

  if (!illegal_insn_seen) test_fail(2);
  print_str("trap_vec_check: PASS\n");
  test_pass();
}
