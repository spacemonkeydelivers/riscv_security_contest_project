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
    # enable external interrupts
    li s0, 8
    csrw mstatus, s0

    # setup main app stack
    mv s0, zero
    la sp, __APP_STACK_TOP
    la a0, main
    call __libc_start_main

    mv ra, a0
1:
    j 1b
    wfi

.section ".__application_stack", "a", @nobits

