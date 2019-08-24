#include <defines.S>

/*
UART_CHECK:ENABLED
A
*/

.global __start

.section .reset, "awx"
__start:
lui sp, 0x80000
addi a0, zero, 0x41
sb a0, 3(sp)
addi zero, zero, 0
addi zero, zero, 0
addi zero, zero, 0
addi zero, zero, 0
addi zero, zero, 0
addi zero, zero, 0
addi zero, zero, 0
addi zero, zero, 0
addi zero, zero, 0
addi zero, zero, 0
addi zero, zero, 0
addi zero, zero, 0
addi zero, zero, 0
addi zero, zero, 0
addi zero, zero, 0
addi zero, zero, 0
addi zero, zero, 0
addi zero, zero, 0
addi zero, zero, 0
addi zero, zero, 0
addi zero, zero, 0
addi zero, zero, 0
addi zero, zero, 0
addi zero, zero, 0
addi zero, zero, 0
addi zero, zero, 0
addi zero, zero, 0
addi zero, zero, 0
addi zero, zero, 0
addi zero, zero, 0
addi zero, zero, 0
addi zero, zero, 0
addi zero, zero, 0
addi zero, zero, 0
addi zero, zero, 0
addi zero, zero, 0
addi zero, zero, 0
addi zero, zero, 0
addi zero, zero, 0
addi zero, zero, 0
addi zero, zero, 0
addi zero, zero, 0
addi zero, zero, 0
addi zero, zero, 0
addi zero, zero, 0
addi zero, zero, 0
addi zero, zero, 0

PASSED
