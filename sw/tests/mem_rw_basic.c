/*
 * mem_rw_basic - write / read / compare on data memory through C pointers.
 *
 * Every access below is a real load/store on Ibex's data bus (OBI),
 * served by the mem_b array in tb_top.sv. The pointers are absolute
 * addresses in the 0x15000 test scratch area (sw/common/memmap.h), which
 * link.ld keeps free of code, globals and stack.
 *
 *   step 1  one word at a literal address            sw / lw
 *   step 2  data patterns on one word                all-0, all-1, A5/5A ...
 *   step 3  walking-1 across all 32 data bits        catches stuck/shorted bits
 *   step 4  byte and halfword stores                 sb / sh -> data_be lanes
 *   step 5  block fill, then block verify            address-as-data
 *   step 6  initialised global variable              .data copy in crt0.S
 *
 * Result: PASS if no mismatches, otherwise FAIL with the mismatch count
 * as the fail code (sw/common/test_end.h).
 */
#include <stdint.h>
#include "../common/memmap.h"
#include "../common/print.h"
#include "../common/test_end.h"

static uint32_t errors;                      /* .bss, zeroed by crt0.S   */
static uint32_t init_global = 0xC0FFEE11u;   /* .data, copied by crt0.S  */

/* Compare one value and log a mismatch. Keeps going after an error so a
 * single run reports every bad location, not just the first. */
static void check(const char *what, uint32_t addr, uint32_t exp, uint32_t got) {
  if (got != exp) {
    errors++;
    printf("  MISMATCH %s addr=%x exp=%x got=%x\n", what, addr, exp, got);
  }
}

int main(void) {
  print_str("mem_rw_basic: start\n");

  /* ---- step 1: one word at an absolute address -------------------- */
  /* `volatile` forces the compiler to really issue every load/store -
   * without it, GCC may keep the value in a register and never touch
   * the bus, and the test would check nothing. */
  volatile uint32_t *p = (volatile uint32_t *)0x00015000;

  *p = 0x12345678u;                 /* store word -> data_we=1, be=4'b1111 */
  uint32_t rd = *p;                 /* load word  -> data_we=0            */
  printf("[1] wrote %x to %x, read back %x\n", 0x12345678u, (uint32_t)p, rd);
  check("word", (uint32_t)p, 0x12345678u, rd);

  /* ---- step 2: data patterns on one word -------------------------- */
  static const uint32_t patterns[] = {   /* const -> .rodata, lives in ROM */
    0x00000000u, 0xFFFFFFFFu, 0xA5A5A5A5u, 0x5A5A5A5Au, 0xDEADBEEFu
  };
  for (uint32_t i = 0; i < sizeof(patterns) / sizeof(patterns[0]); i++) {
    *p = patterns[i];
    check("pattern", (uint32_t)p, patterns[i], *p);
  }
  print_str("[2] patterns done\n");

  /* ---- step 3: walking-1 ------------------------------------------ */
  for (uint32_t bit = 0; bit < 32; bit++) {
    *p = 1u << bit;
    check("walk1", (uint32_t)p, 1u << bit, *p);
  }
  print_str("[3] walking-1 done\n");

  /* ---- step 4: byte and halfword stores --------------------------- */
  /* Same memory, three pointer types. A uint8_t store becomes `sb`
   * (one data_be bit set), uint16_t becomes `sh` (two bits). RISC-V is
   * little-endian: byte 0 is the least significant byte of the word. */
  volatile uint32_t *w  = (volatile uint32_t *)(SCRATCH_BASE + 0x10);
  volatile uint8_t  *b  = (volatile uint8_t  *)(SCRATCH_BASE + 0x10);
  volatile uint16_t *h  = (volatile uint16_t *)(SCRATCH_BASE + 0x10);

  *w = 0;
  b[0] = 0x11; b[1] = 0x22; b[2] = 0x33; b[3] = 0x44;
  check("bytes->word", (uint32_t)w, 0x44332211u, *w);
  check("byte read",   (uint32_t)&b[2], 0x33u, b[2]);

  *w = 0xFFFFFFFFu;
  b[1] = 0x00;                      /* only lane 1 may change */
  check("byte merge", (uint32_t)w, 0xFFFF00FFu, *w);

  h[0] = 0xBEEF; h[1] = 0xCAFE;
  check("halves->word", (uint32_t)w, 0xCAFEBEEFu, *w);
  check("half read",    (uint32_t)&h[1], 0xCAFEu, h[1]);
  printf("[4] byte/halfword lanes done, word now %x\n", *w);

  /* ---- step 5: block fill, then verify ---------------------------- */
  /* Writing every location first and reading afterwards (instead of
   * write-read per word) catches address aliasing: a broken address
   * line would let a later write overwrite an earlier location. */
  volatile uint32_t *blk = (volatile uint32_t *)(SCRATCH_BASE + 0x100);
  const uint32_t     nwords = 64;

  for (uint32_t i = 0; i < nwords; i++)
    blk[i] = (uint32_t)&blk[i];     /* data = own address */
  for (uint32_t i = 0; i < nwords; i++)
    check("block", (uint32_t)&blk[i], (uint32_t)&blk[i], blk[i]);
  printf("[5] block %x..%x verified\n",
         (uint32_t)&blk[0], (uint32_t)&blk[nwords - 1]);

  /* ---- step 6: an ordinary global is memory too ------------------- */
  /* No absolute address here - the linker picked one in RAM. Taking
   * its address shows where it landed. */
  printf("[6] init_global at %x = %x\n", (uint32_t)&init_global, init_global);
  check("global", (uint32_t)&init_global, 0xC0FFEE11u, init_global);

  /* ---- result ----------------------------------------------------- */
  if (errors) {
    printf("mem_rw_basic: FAIL, %d mismatches\n", errors);
    test_fail(errors);
  }
  print_str("mem_rw_basic: PASS\n");
  test_pass();
}
