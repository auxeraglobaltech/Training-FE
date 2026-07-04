# ============================================================
#  Layer-A software testcases (run ON the Vortex core).
#  Bare-metal rv32im + common crt0; output = byte-addressed .hex images
#  consumed by the TB mem model ($readmemh) + optional .expected.hex
#  golden files consumed by the scoreboard.
#
#  Toolchain: /home/user1/vortex (riscv32-unknown-elf-gcc 12.2.0)
# ============================================================
TOOLDIR   ?= /home/user1/vortex
RISCV_BIN := $(TOOLDIR)/riscv32-gnu-toolchain/bin/riscv32-unknown-elf
CC        := $(RISCV_BIN)-gcc
OBJCOPY   := $(RISCV_BIN)-objcopy
OBJDUMP   := $(RISCV_BIN)-objdump

COMMON  := common
CFLAGS  := -march=rv32imf_zicsr -mabi=ilp32 -O2 -ffreestanding -nostdlib \
           -nostartfiles -fno-builtin -Wall \
           -T $(COMMON)/link.ld $(COMMON)/crt0.S
BASE    := 0x80000000

ASM_TESTS := tests/asm/self_check tests/asm/divergence
C_TESTS   := tests/c/vecadd tests/c/memcpy_stride tests/c/ctrl_flow tests/c/fp_ops

ALL_HEX := $(addsuffix .hex,$(ASM_TESTS) $(C_TESTS)) tests/c/vecadd.expected.hex

all: $(ALL_HEX)

%.elf: %.S $(COMMON)/crt0.S $(COMMON)/link.ld
	$(CC) $(CFLAGS) $< -o $@
	$(OBJDUMP) -d $@ > $*.dis

%.elf: %.c $(COMMON)/crt0.S $(COMMON)/link.ld
	$(CC) $(CFLAGS) $< -o $@
	$(OBJDUMP) -d $@ > $*.dis

%.hex: %.elf
	$(OBJCOPY) -O binary $< $*.bin
	python3 $(COMMON)/bin2hex.py $*.bin $@ $(BASE)

tests/c/vecadd.expected.hex: tests/c/vecadd_expected.py
	python3 $< > $@

clean:
	rm -f tests/*/*.elf tests/*/*.bin tests/*/*.dis \
	      $(addsuffix .hex,$(ASM_TESTS) $(C_TESTS)) tests/c/vecadd.expected.hex

.PHONY: all clean
.PRECIOUS: %.elf
