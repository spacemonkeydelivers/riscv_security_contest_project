#ifndef D_RISCV_SOC_TESTS_BOOT_INCLUDE_GUARD
#define D_RISCV_SOC_TESTS_BOOT_INCLUDE_GUARD

#include <defines.S>

.global __start
.weak ON_EXCEPTION_handler

.section .reset, "awx"
__start:
    la t1, ON_EXCEPTION_handler
    csrw mtvec, t1
    li t2, 0x80
    csrw mie, t2
    li t2, 8
    csrw mstatus, 8
    j main

#endif // D_RISCV_SOC_TESTS_BOOT_INCLUDE_GUARD
