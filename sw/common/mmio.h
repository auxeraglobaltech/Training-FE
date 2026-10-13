#ifndef MMIO_H
#define MMIO_H

#include <stdint.h>

/* Linked symbols defined in crt0.S's .data block - using these instead of
 * raw pointer casts guarantees the addresses tb_top.sv/ibex_driver.sv
 * hardwire (0x10000, 0x10004) can never be silently reused by an
 * unrelated test global. */
extern volatile uint32_t tohost;
extern volatile uint32_t irq_ctrl;

#endif /* MMIO_H */
