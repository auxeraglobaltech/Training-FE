#ifndef PRINT_H
#define PRINT_H

/* C-side console. Each character is one 32-bit store to CONSOLE_TX; the
 * ibex_console UVM component (tb/env/ibex_console.sv) collects them and
 * prints one line per '\n' as:   UVM_INFO ... [C_PRINT] <your text>
 *
 *   print_str("hello\n");
 *   print_hex(0x15000);              -> 0x00015000
 *   print_dec(-42);                  -> -42
 *   printf("addr=%x data=%d\n", a, d);
 *
 * printf supports a small subset: %d %u %x %s %c %%. No widths/flags;
 * %x always prints 0x plus 8 hex digits. Built with -ffreestanding, so
 * GCC treats this printf as an ordinary function, not the libc one.
 * Text without a trailing '\n' stays buffered in SV until the next '\n'.
 */

#include <stdint.h>
#include <stdarg.h>
#include "memmap.h"

static inline void print_char(char c) {
  REG32(CONSOLE_TX) = (uint32_t)(uint8_t)c;
}

static inline void print_str(const char *s) {
  while (*s) print_char(*s++);
}

static inline void print_hex(uint32_t v) {
  print_str("0x");
  for (int shift = 28; shift >= 0; shift -= 4)
    print_char("0123456789abcdef"[(v >> shift) & 0xF]);
}

static inline void print_udec(uint32_t v) {
  char buf[10];
  int  n = 0;
  do { buf[n++] = (char)('0' + v % 10); v /= 10; } while (v);
  while (n) print_char(buf[--n]);
}

static inline void print_dec(int32_t v) {
  if (v < 0) { print_char('-'); print_udec(0u - (uint32_t)v); }
  else       { print_udec((uint32_t)v); }
}

static inline void printf(const char *fmt, ...) {
  va_list ap;
  va_start(ap, fmt);
  for (; *fmt; fmt++) {
    if (*fmt != '%') { print_char(*fmt); continue; }
    switch (*++fmt) {
      case 'd': print_dec(va_arg(ap, int32_t));           break;
      case 'u': print_udec(va_arg(ap, uint32_t));         break;
      case 'x': print_hex(va_arg(ap, uint32_t));          break;
      case 's': print_str(va_arg(ap, const char *));      break;
      case 'c': print_char((char)va_arg(ap, int));        break;
      case '%': print_char('%');                          break;
      case '\0': va_end(ap); return;                      /* lone '%' at end */
      default:  print_char('%'); print_char(*fmt);        break;
    }
  }
  va_end(ap);
}

#endif /* PRINT_H */
