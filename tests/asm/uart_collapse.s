#include <defines.S>
#include <boot.S>

.text
main:
    la sp, UART_BASE_ADDR
    la a0, 0x41
    sb a0, 0(sp)
    PASSED


