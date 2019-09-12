#ifndef D_RISCV_SOC_TESTS_BOOT_INCLUDE_GUARD
#define D_RISCV_SOC_TESTS_BOOT_INCLUDE_GUARD

#include <defines.S>

.global __start
.weak ON_EXCEPTION_handler

.section .reset, "awx"
__start:
    la t1, ON_EXCEPTION_handler
    csrw mtvec, t1
    // Interrupts should be disabled
    li t2, 0x00
    csrw mie, t2
    li t2, 8
    csrw mstatus, 8
    li t2, 13889
    li t1, UART_DIV_ADDR
    sw t2, 0(t1)
    j main

#endif // D_RISCV_SOC_TESTS_BOOT_INCLUDE_GUARD
