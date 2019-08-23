#ifndef D_RISCV_SOC_TESTS_BOOT_INCLUDE_GUARD
#define D_RISCV_SOC_TESTS_BOOT_INCLUDE_GUARD

#include <defines.S>

.global __start
.weak ON_EXCEPTION

.section .reset, "awx"
__start:
    la t1, ON_EXCEPTION
    csrw mtvec, t1
    li t2, 8
    csrw mstatus, 8
    j main

#endif // D_RISCV_SOC_TESTS_BOOT_INCLUDE_GUARD
