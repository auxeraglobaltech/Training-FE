#ifndef TRAP_H
#define TRAP_H

#include <stdint.h>

/* Each test defines this for the causes it cares about; a weak default
 * in crt0.S (forwards mcause to tohost, halts) covers tests that don't.
 *
 * Returns the PC execution should resume at via mret - usually just
 * `mepc` unchanged. trap_common (crt0.S) writes this return value into
 * its saved-mepc stack slot before restoring the mepc CSR, so this is
 * the only supported way to change the resume address; a plain
 * `write_csr(mepc, ...)` from inside the handler gets silently
 * overwritten.
 */
uint32_t trap_c_handler(uint32_t mcause, uint32_t mepc, uint32_t mtval);

#endif /* TRAP_H */
