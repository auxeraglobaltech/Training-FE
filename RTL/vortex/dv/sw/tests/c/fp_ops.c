// FP test (exercises FPNEW): add/mul/sub/div/fma-shaped expressions on
// exactly-representable values, plus int<->float conversions and compares.
// All results are bit-exact powers-of-two arithmetic — no rounding cases.

#define OUT_ADDR 0x80020000u
#define N        8

int main(void) {
  volatile float    *outf = (volatile float *)OUT_ADDR;
  volatile unsigned *outi = (volatile unsigned *)(OUT_ADDR + 0x100);
  float a[N], b[N];

  for (int i = 0; i < N; i++) {
    a[i] = (float)(i + 1);          // 1..8
    b[i] = 0.5f * (float)(i + 2);   // 1.0, 1.5, ... exactly representable
  }

  for (int i = 0; i < N; i++) outf[i]         = a[i] + b[i];
  for (int i = 0; i < N; i++) outf[N + i]     = a[i] * b[i];
  for (int i = 0; i < N; i++) outf[2 * N + i] = a[i] * b[i] + a[i]; // fma shape
  for (int i = 0; i < N; i++) outf[3 * N + i] = a[i] / 2.0f;

  // conversions + compares
  outi[0] = (unsigned)(a[7] * 4.0f);            // 32
  outi[1] = (a[3] > b[3]) ? 1u : 0u;            // 4.0 > 2.5 -> 1
  outi[2] = (unsigned)((float)100 / 4.0f);      // 25

  for (int i = 0; i < N; i++) {
    if (outf[i]         != (float)(i + 1) + 0.5f * (float)(i + 2)) return 1;
    if (outf[N + i]     != (float)(i + 1) * (0.5f * (float)(i + 2))) return 2;
    if (outf[2 * N + i] != (float)(i + 1) * (0.5f * (float)(i + 2))
                           + (float)(i + 1)) return 3;
    if (outf[3 * N + i] != (float)(i + 1) / 2.0f) return 4;
  }
  if (outi[0] != 32) return 5;
  if (outi[1] != 1)  return 6;
  if (outi[2] != 25) return 7;
  return 0;
}
