#!/usr/bin/env python3
"""Flat binary -> byte-addressed $readmemh image at a base address."""
import sys

def main():
    if len(sys.argv) != 4:
        print("usage: bin2hex.py <in.bin> <out.hex> <base_addr_hex>")
        return 1
    data = open(sys.argv[1], "rb").read()
    base = int(sys.argv[3], 16)
    with open(sys.argv[2], "w") as f:
        f.write(f"@{base:08X}\n")
        for i in range(0, len(data), 16):
            f.write(" ".join(f"{b:02X}" for b in data[i:i+16]) + "\n")
    return 0

if __name__ == "__main__":
    sys.exit(main())
