// Control-flow test: loops, nested branches, function calls, recursion.
// fib(12)=144, collatz steps(27)=111, gcd(1071,462)=21, bit-count.

#define OUT_ADDR 0x80020000u

static unsigned fib(unsigned n) {
  return (n < 2) ? n : fib(n - 1) + fib(n - 2);
}

static unsigned collatz(unsigned n) {
  unsigned steps = 0;
  while (n != 1) {
    n = (n & 1) ? 3 * n + 1 : n / 2;
    steps++;
  }
  return steps;
}

static unsigned gcd(unsigned a, unsigned b) {
  while (b) { unsigned t = b; b = a % b; a = t; }
  return a;
}

int main(void) {
  volatile unsigned *out = (volatile unsigned *)OUT_ADDR;
  unsigned pop = 0, x = 0xF00F5A5Au;
  while (x) { pop += x & 1; x >>= 1; }

  out[0] = fib(12);
  out[1] = collatz(27);
  out[2] = gcd(1071, 462);
  out[3] = pop;

  if (out[0] != 144) return 1;
  if (out[1] != 111) return 2;
  if (out[2] != 21)  return 3;
  if (out[3] != 16)  return 4;
  return 0;
}
