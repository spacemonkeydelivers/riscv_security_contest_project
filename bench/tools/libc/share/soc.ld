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
    .data : {
        *(.data)
    }
    .rodata : {
        *(.rodata)
    }
    .bss : {
        __bss_start = .;
        *(.bss)
        *(.sbss)
        __bss_end = .;

    }

    .heap (NOLOAD) : {
        . = ALIGN(16) ;
        __heap_start = . ;
        . =  . + HEAP_SIZE ;
        __heap_end = . ;
    }


    /* Stack code mapping */
    .application_stack __heap_end : {
        __APP_STACK_BOTTOM = .;
        *(.__application_stack);
        . = __APP_STACK_BOTTOM + STACK_SIZE;
        __APP_STACK_TOP = ((. + 15) & ( ~ 15 )) ;
    }
    __SOC_MEM_SIZE  = DEFINED(__SOC_MEM_SIZE) ? __SOC_MEM_SIZE : 8192 ;
    /* TODO: add assert for available memory */
    ASSERT(__APP_STACK_TOP <= __SOC_MEM_SIZE, "not enough memory")
}


