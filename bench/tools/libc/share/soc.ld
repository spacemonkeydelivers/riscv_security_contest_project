SECTIONS
{
    _start = 0;
    ENTRY(_start)
    /* BIOS mapping */
    .reset 0x0 : AT(0x0) {
        *(.reset);
    }
    /* System code mapping */
    .system : {
        *(.__system.init)
        *(.__system.isr)
        *(.__system.os)
        *(.__system.data)
    }
    /* User code mapping */
    .text 0x400000 : AT(0x400000) {
        *(.text)
    }
    .data : {
        *(.data)
    }
    .rodata : {
        *(.rodata)
    }
    .bss : {
        *(.bss)
    }
    /* Stack code mapping */
    .__application_stack 0x7ffff000 : AT(0x7ffff000) {
        begin = .;
        *(.__application_stack);
        . = begin + 4096;
    }
}


