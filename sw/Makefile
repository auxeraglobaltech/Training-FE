CROSS   = /home/user1/riscv/bin/riscv32-unknown-elf
CC      = $(CROSS)-gcc
OBJCOPY = $(CROSS)-objcopy
CFLAGS  = -march=rv32imc_zicsr -mabi=ilp32 -Os -nostartfiles -nostdlib \
          -ffreestanding -Isw/common -Tsw/link.ld
TEST    = hello_world
SRC     = sw/crt0.S sw/tests/$(TEST).c
ELF     = sim/$(TEST).elf
VMEM    = sim/$(TEST).vmem

all: $(VMEM)
	@echo "SW build complete: $(VMEM)"

$(ELF): $(SRC) sw/link.ld
	$(CC) $(CFLAGS) -o $@ $(SRC)

$(VMEM): $(ELF)
	$(OBJCOPY) -O verilog $< $@
	@echo "Generated $(VMEM)"

clean:
	rm -f sim/*.elf sim/*.vmem

.PHONY: all clean
