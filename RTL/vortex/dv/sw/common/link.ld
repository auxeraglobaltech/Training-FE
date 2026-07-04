/* Minimal bare-metal layout for Vortex DV testcases.
   Image is loaded flat at 0x8000_0000 = VX_DCR_KMU_STARTUP_ADDR0. */
OUTPUT_ARCH(riscv)
ENTRY(_start)

MEMORY {
  RAM (rwx) : ORIGIN = 0x80000000, LENGTH = 0x100000
}

SECTIONS {
  .text : { *(.init) *(.text*) } > RAM
  .rodata : { *(.rodata*) *(.srodata*) } > RAM
  .data : { *(.data*) *(.sdata*) } > RAM
  .bss : { __bss_start = .; *(.bss*) *(.sbss*) *(COMMON); __bss_end = .; } > RAM
  _end = .;
}
