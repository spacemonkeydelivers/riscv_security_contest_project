SECTIONS
{
    /* this is the reset address */
    __start = 0x0;
    ENTRY(__start)
    /* the assembly should be placed in  in .text section */
    .reset 0 : AT(0) {
        *(.reset);
    }
}
