MEMORY {
  ROM (rx)  : ORIGIN = 0x00000000, LENGTH = 64K
  RAM (rwx) : ORIGIN = 0x00010000, LENGTH = 128K
}

SECTIONS {
  /* Ibex always fetches its first post-reset instruction from
     boot_addr_i + 0x80 (boot_addr_i = 0 in this environment, so
     physical address 0x80). Reserve that address for a dedicated
     trampoline instead of leaving it zeroed - a zero word decodes
     as an illegal instruction, which happened to trap to _start
     only because mtvec's reset value (0x0) coincides with the ROM
     origin. That is a coincidence, not a boot path. */
  .text.reset_vector 0x80 : {
    KEEP(*(.text.reset_vector))
  } > ROM

  /* Ibex forces mtvec[7:0] to 0b00000001 on every write and passes
     mtvec[31:8] through unrounded (truncated, not rounded) - see
     ibex_cs_registers.sv. trap_vectors must therefore sit at a true
     256-byte-aligned address or the effective base silently lands below
     it; ALIGN(256) here guarantees that regardless of how much code
     precedes it. */
  .text.trap_vec : ALIGN(256) {
    KEEP(*(.text.trap_vec))
  } > ROM

  .text : {
    *(.text.start)
    *(.text.trap)
    *(.text.trap_default)
    *(.text*)
    *(.rodata*)
  } > ROM

  /* TB mailbox words (tohost @ 0x10000, irq_ctrl @ 0x10004). NOLOAD:
     they have no image in ROM and are never touched by crt0's .data
     copy loop - the TB treats ANY store to tohost as end-of-test, so a
     startup write of 0 there would end every test as a failure. They
     rely on tb_top zero-filling memory at time 0 instead. */
  .tohost ORIGIN(RAM) (NOLOAD) : {
    KEEP(*(.tohost))
  } > RAM

  /* Initialised globals: linked to run from RAM (VMA) but stored in ROM
     (LMA), because the .vmem image is built from load addresses.
     crt0.S copies [_data_lma, +size) -> [_data_start, _data_end) before
     main(), otherwise `int x = 5;` would read back as 0. */
  .data : {
    _data_start = .;
    *(.sdata*)
    *(.data*)
    . = ALIGN(4);
    _data_end = .;
  } > RAM AT > ROM
  _data_lma = LOADADDR(.data);

  .bss : {
    _bss_start = .;
    *(.sbss*)
    *(.bss*)
    *(COMMON)
    . = ALIGN(4);
    _bss_end = .;
  } > RAM
}

_stack_top = ORIGIN(RAM) + LENGTH(RAM);

/* 0x15000-0x15FFF is a test scratch area (SCRATCH_BASE in
   sw/common/memmap.h) that C tests access through absolute pointers.
   The linker never places anything there; this check fails the build if
   .data/.bss ever grow far enough to collide with it. */
ASSERT(_bss_end <= 0x15000, "globals overflow into the 0x15000 test scratch area")
ASSERT(tohost == 0x10000, "tohost must sit at 0x10000 - tb_top/ibex_monitor hardwire it")
