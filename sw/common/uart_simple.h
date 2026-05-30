#ifndef UART_SIMPLE_H
#define UART_SIMPLE_H

#define UART_BASE    0x20000
#define UART_TX_REG  (*(volatile unsigned int *)(UART_BASE))

static inline void uart_putc(char c) { UART_TX_REG = (unsigned int)c; }
static inline void uart_puts(const char *s) { while (*s) uart_putc(*s++); }

#endif /* UART_SIMPLE_H */
