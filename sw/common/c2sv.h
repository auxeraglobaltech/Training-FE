#ifndef C2SV_H
#define C2SV_H

/* C <-> SV handshake. Lets a C test hand control to the SV testbench at a
 * chosen point, wait until SV has finished its part, and carry on.
 *
 *   C side (this file)                  SV side (tb/env/ibex_c2sv_mbox.sv,
 *                                                the test's handle_c_cmd())
 *   ---------------------------------   ---------------------------------
 *   C2SV_ARG = arg
 *   C2SV_CMD = cmd        ------------> sees the CMD store, clears ACK,
 *                                       calls handle_c_cmd(cmd, arg)
 *   spin: while (SV2C_ACK != cmd)       ... SV does its work (any number
 *                                           of clock cycles) ...
 *                         <------------ SV2C_DATA = result, SV2C_ACK = cmd
 *   return SV2C_DATA
 *
 * Rules:
 *   - cmd must be non-zero (ACK = 0 means "SV busy").
 *   - Write ARG before CMD: the CMD store is what wakes SV.
 *   - The command ids and what they mean are a contract between one C
 *     test and its SV test class - define them in one shared place.
 */

#include <stdint.h>
#include "memmap.h"

static inline uint32_t sv_sync(uint32_t cmd, uint32_t arg) {
  REG32(C2SV_ARG) = arg;
  REG32(C2SV_CMD) = cmd;
  while (REG32(SV2C_ACK) != cmd) { }    /* SV is running its part */
  return REG32(SV2C_DATA);
}

#endif /* C2SV_H */
