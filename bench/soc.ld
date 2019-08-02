SECTIONS
{
    /* this is the reset address */
    __reset = 0x0;
    ENTRY(__reset)
    /* the assembly should be placed in  in .text section */
    .text 0 : {
        *(.text);
    }
}
