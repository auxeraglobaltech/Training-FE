CROSS   = /home/user1/riscv/bin/riscv32-unknown-elf
CC      = $(CROSS)-gcc
OBJCOPY = $(CROSS)-objcopy
OBJDUMP = $(CROSS)-objdump

CFLAGS  = -march=rv32imc_zicsr -mabi=ilp32 -Os -g -nostartfiles -nostdlib \
          -ffreestanding -Isw/common -Tsw/link.ld

TEST    = hello_world
SRC     = sw/crt0.S sw/tests/$(TEST).c
ELF     = sim/$(TEST).elf
VMEM    = sim/$(TEST).vmem
DIS     = sim/$(TEST).dis

all: $(VMEM) $(DIS)
	@echo "SW build complete: $(VMEM)  $(DIS)"

$(ELF): $(SRC) sw/link.ld
	$(CC) $(CFLAGS) -o $@ $(SRC)

$(VMEM): $(ELF)
	$(OBJCOPY) -O verilog $< $@
	@echo "Generated $(VMEM)"

$(DIS): $(ELF)
	$(OBJDUMP) -d -S $< > $@
	@echo "Generated $(DIS)"

clean:
	rm -f sim/*.elf sim/*.vmem sim/*.dis

.PHONY: all clean
