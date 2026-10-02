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

  .text : {
    *(.text.start)
    *(.text.trap)
    *(.text*)
    *(.rodata*)
  } > ROM

  .data : {
    *(.data*)
  } > RAM AT > ROM

  .bss : {
    _bss_start = .;
    *(.bss*)
    *(COMMON)
    _bss_end = .;
  } > RAM
}

_stack_top = ORIGIN(RAM) + LENGTH(RAM);
