// ============================================================
//  DPI-C golden reference, compiled INTO the simulation by xrun
//  (HYBRID=1 adds this file to the command line). The UVM scoreboard
//  imports vx_ref_num_words()/vx_ref_word() and cross-checks the DUT's
//  output memory region against this independent C model — the same
//  algorithm the kernel runs on the core, recomputed on the host.
// ============================================================
#include <string.h>

// vecadd.c golden: c[i] = a[i]+b[i] = 10i+3, N=16, words at OUT+4i
static unsigned ref_vecadd(int i) { return 10u * (unsigned)i + 3u; }

// ctrl_flow.c golden: fib(12), collatz(27), gcd(1071,462), popcount
static unsigned ref_ctrl_flow(int i) {
    static const unsigned v[4] = {144u, 111u, 21u, 16u};
    return v[i];
}

// memcpy_stride.c golden: three byte regions packed as words (little-endian)
static unsigned ref_memcpy_byte(int b) {
    if (b < 64)  return (unsigned char)(b * 5 + 1);                 // fwd
    if (b < 128) return (unsigned char)((63 - (b - 64)) * 5 + 1);   // bwd
    return (unsigned char)(4 * (b - 128) * 5 + 1);                  // stride
}
static unsigned ref_memcpy(int i) {
    unsigned w = 0;
    for (int k = 0; k < 4; k++)
        w |= ref_memcpy_byte(4 * i + k) << (8 * k);
    return w;
}

int vx_ref_num_words(const char* test) {
    if (!strcmp(test, "vecadd"))        return 16;
    if (!strcmp(test, "ctrl_flow"))     return 4;
    if (!strcmp(test, "memcpy_stride")) return 36;   // 144 bytes
    return 0;
}

unsigned vx_ref_word(const char* test, int i) {
    if (!strcmp(test, "vecadd"))        return ref_vecadd(i);
    if (!strcmp(test, "ctrl_flow"))     return ref_ctrl_flow(i);
    if (!strcmp(test, "memcpy_stride")) return ref_memcpy(i);
    return 0xDEADDEAD;
}
