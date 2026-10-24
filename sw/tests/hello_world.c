/*
 * hello_world - smallest possible test: print a line, then pass by
 * returning 0 from main (crt0.S turns that into tohost = 1).
 */
#include "../common/print.h"

int main(void) {
  print_str("Hello from Ibex!\n");
  return 0;
}
