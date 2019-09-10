SECTIONS
{
    /* this is the reset address */
    __start = 0x0;
    ENTRY(__start)
    /* the assembly should be placed in  in .text section */
    .reset 0 : AT(0) {
        *(.reset);
        *(.text);
    }
    . = ALIGN(16) ;
    .results : {
        __marker_test_end = . ;
        LONG(0xdeadbabe) ;
        __marker_test_status = . ;
        LONG(0xdeadbabe) ; 
        __marker_test_pad0 = . ;
        LONG(0xdeadbabe) ; 
        __marker_test_pad1 = . ;
        LONG(0xdeadbabe) ; 
    }
}
