// memcpy + strided access patterns: forward copy, backward copy, stride-4
// gather. Exercises dcache line reuse and byteen'd partial writes (bytes).
// Self-checking; output region at OUT_ADDR for the scoreboard/DPI ref.

#define N        64
#define OUT_ADDR 0x80020000u

static unsigned char src[N];

int main(void) {
  volatile unsigned char *dst = (volatile unsigned char *)OUT_ADDR;

  for (int i = 0; i < N; i++) src[i] = (unsigned char)(i * 5 + 1);

  // forward byte copy
  for (int i = 0; i < N; i++) dst[i] = src[i];
  // backward copy into second region
  for (int i = N - 1; i >= 0; i--) dst[N + i] = src[N - 1 - i];
  // stride-4 gather into third region
  for (int i = 0; i < N / 4; i++) dst[2 * N + i] = src[4 * i];

  for (int i = 0; i < N; i++)
    if (dst[i] != (unsigned char)(i * 5 + 1)) return 1;
  for (int i = 0; i < N; i++)
    if (dst[N + i] != (unsigned char)((N - 1 - i) * 5 + 1)) return 2;
  for (int i = 0; i < N / 4; i++)
    if (dst[2 * N + i] != (unsigned char)(4 * i * 5 + 1)) return 3;
  return 0;
}
