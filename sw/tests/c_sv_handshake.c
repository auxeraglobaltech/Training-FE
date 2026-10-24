/*
 * c_sv_handshake - hand control back and forth between C and SV.
 *
 * Run with the matching SV test:  TEST=c_sv_handshake
 *                                 TEST_NAME=ibex_c_sv_sync_test
 *
 * The C program is the "master" of the flow: it runs, and at each
 * sv_sync() it stops and waits while the SV test runs its part for that
 * command (tb/tests/ibex_c_sv_sync_test.sv, handle_c_cmd). When SV
 * replies, C continues from the next line.
 *
 *   C part 1  -> SV: CMD_SV_WAIT     SV runs for N clocks, C waits
 *   C part 2  -> SV: CMD_SV_COMPUTE  data both ways: C sends, SV returns
 *   C part 3  -> SV: CMD_IRQ_ON      SV drives a DUT pin, C observes it
 *            -> SV: CMD_IRQ_OFF
 *   C part 4  end of test
 */
#include <stdint.h>
#include "../common/csr.h"
#include "../common/c2sv.h"
#include "../common/print.h"
#include "../common/test_end.h"

/* Command ids - must match the localparams in ibex_c_sv_sync_test.sv. */
#define CMD_SV_WAIT     1u   /* SV waits `arg` clocks, returns arg        */
#define CMD_SV_COMPUTE  2u   /* SV returns arg * 2 + 1                    */
#define CMD_IRQ_ON      3u   /* SV asserts irq_external_i                 */
#define CMD_IRQ_OFF     4u   /* SV deasserts irq_external_i               */

int main(void) {
  uint32_t r;

  /* ---- C part 1 --------------------------------------------------- */
  print_str("C : part 1 running, handing over to SV\n");
  r = sv_sync(CMD_SV_WAIT, 50);
  printf("C : back from SV (it ran %d clocks), continuing\n", r);

  /* ---- C part 2: data exchange ------------------------------------ */
  uint32_t sent = 20;
  r = sv_sync(CMD_SV_COMPUTE, sent);
  printf("C : sent %d, SV returned %d\n", sent, r);
  if (r != sent * 2 + 1) test_fail(1);

  /* ---- C part 3: SV drives the DUT, C checks the effect ----------- */
  /* mie is 0 (crt0.S), so the pin shows up in mip but cannot trap. */
  if (read_csr(mip) & MIE_MEIE) test_fail(2);       /* must start low  */
  sv_sync(CMD_IRQ_ON, 0);
  if (!(read_csr(mip) & MIE_MEIE)) test_fail(3);    /* SV raised it    */
  print_str("C : sees mip.MEIP=1 after SV raised irq_external\n");
  sv_sync(CMD_IRQ_OFF, 0);
  if (read_csr(mip) & MIE_MEIE) test_fail(4);       /* SV dropped it   */
  print_str("C : sees mip.MEIP=0 after SV dropped it\n");

  /* ---- C part 4 --------------------------------------------------- */
  print_str("C : all steps done\n");
  test_pass();
}
