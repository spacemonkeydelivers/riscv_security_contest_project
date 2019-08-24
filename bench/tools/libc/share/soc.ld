SECTIONS
{
    STACK_SIZE = 4096;
    HEAP_SIZE = 12288; /* 12K */
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
        *(.__libgcc_)
        *(.__system.data)
        *(.__system.secure_data)
    }
    /* User code mapping */
    .text : {
        *(.text)
    }
    .data ALIGN(16): {
        *(.data)
    }
    .rodata ALIGN(16): {
        *(.rodata)
    }
    .bss ALIGN(16): {
        __bss_start = .;
        *(.bss)
        __bss_end = .;
    }
    __heap_start = ALIGN(16) ;
    __heap_end = . + HEAP_SIZE ;

    /* Stack code mapping */
    .application_stack __heap_end : {
        begin = .;
        *(.__application_stack);
        . = begin + STACK_SIZE;
    }
    __SOC_MEM_SIZE  = DEFINED(__SOC_MEM_SIZE) ? __SOC_MEM_SIZE : 8192 ;
    __APP_STACK_TOP = ((. + 15) & ( ~ 15 )) ;
    /* TODO: add assert for available memory */
    ASSERT(__APP_STACK_TOP <= __SOC_MEM_SIZE, "not enough memory")
}


