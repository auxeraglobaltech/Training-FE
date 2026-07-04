#!/usr/bin/env python3
# Golden model for vecadd.c: emits "<byte_addr_hex> <word_hex>" lines
# consumed by vx_scoreboard (+EXPECTED=...).
N = 16
OUT = 0x80020000
for i in range(N):
    print(f"{OUT + 4*i:08x} {10*i + 3:08x}")
