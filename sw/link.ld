MEMORY {
  ROM (rx)  : ORIGIN = 0x00000000, LENGTH = 64K
  RAM (rwx) : ORIGIN = 0x00010000, LENGTH = 128K
}

SECTIONS {
  .text : {
    *(.text.start)
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
