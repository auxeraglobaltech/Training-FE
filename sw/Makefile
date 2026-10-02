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
PDIS    = sim/$(TEST).pdis

all: $(VMEM) $(DIS) $(PDIS)
	@echo "SW build complete: $(VMEM)  $(DIS)  $(PDIS)"

$(ELF): $(SRC) sw/link.ld
	$(CC) $(CFLAGS) -o $@ $(SRC)

$(VMEM): $(ELF)
	$(OBJCOPY) -O verilog $< $@
	@echo "Generated $(VMEM)"

# Source-interleaved disassembly (-d -S): best for tracing a given
# instruction back to the C/asm line that produced it.
$(DIS): $(ELF)
	$(OBJDUMP) -d -S $< > $@
	@echo "Generated $(DIS)"

# Plain disassembly (-d only): no interleaved source, compact address/
# opcode/mnemonic listing - easier to scan address-by-address against
# a waveform (e.g. matching pc_if/pc_id in SimVision).
$(PDIS): $(ELF)
	$(OBJDUMP) -d $< > $@
	@echo "Generated $(PDIS)"

clean:
	rm -f sim/*.elf sim/*.vmem sim/*.dis sim/*.pdis

.PHONY: all clean
