#include "lib/defines.S"

.global __start

.section .reset, "awx"
__start:
    la sp, UART_BASE_ADDR
    la a0, 0x41
    sb a0, 0(sp)
    PASSED


