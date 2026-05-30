#include "../common/uart_simple.h"

int main(void) {
  uart_puts("Hello from Ibex!\n");
  volatile unsigned int *tohost = (volatile unsigned int *)0x00010000;
  *tohost = 1;
  return 0;
}
