OUTPUT_ARCH( "riscv" )
ENTRY(_start)

SECTIONS
{
  . = 0x0;
  .text.init : { *(.text.init) }
  /* . = ALIGN(0x1000); */
  . = ALIGN(0x4);
  .tohost : { *(.tohost) }
  /* . = ALIGN(0x1000); */
  . = ALIGN(0x4);
  .text : { *(.text) }
  /* . = ALIGN(0x1000); */
  . = ALIGN(0x4);
  .data : { *(.data) }
  .data.string : { *(.data.string)}
  .bss : { *(.bss) }
  _end = .;

}

