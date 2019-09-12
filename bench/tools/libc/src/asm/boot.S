#include <generated/esf.h>
.global _start

.section ".reset", "ax"
_start:
    __D_INITIALIZE_REGISTER_FILE

# .bss initalization start
    la t1, __bss_start
    la t2, __bss_end
    bge t1, t2, 1f
bss_init:
    sw zero, 0(t1)
    addi t1, t1, 4
    blt t1, t2, bss_init
1:
# .bss initialization end

# set tags for code section
    la t1, __cfg_enable_memtag
    beq zero, t1, 1f
    la t1, _start
    la t2, __text_end
    li t3, 15
0:
    st t3, 0(t1)
    addi t1, t1, 15
    blt t1, t2, 0b
1:
    la sp, __APP_STACK_TOP
    la t1, __isr_wrapper
    csrw mtvec, t1
    la a0, __cfg_enable_memtag
    la a1, __heap_start
    la a2, __heap_end
    sw a0, -12(sp)
    sw a1, -8(sp)
    sw a2, -4(sp)
    addi a0, sp, -12
    addi sp, sp, -16
    call __soc_init
    addi sp, sp, 16
    # enable timer interrupts
    li s0, 0x80
    csrw mie, s0
    # enable global interrupts
    li s0, 8
    csrw mstatus, s0

    # setup main app stack
    la a1, __ARGS_INFO
    addi a2, a1, 4
    lw a1, 0(a1)
    la sp, __APP_STACK_TOP
    la a0, main
    call __libc_start_main

    mv a1, a0
    call exit
.4byte 0xffffffff

.section ".__application_stack", "a", @nobits

