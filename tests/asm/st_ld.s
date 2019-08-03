#include "lib/defines.S"

.global __start

.section .reset, "awx"
__start:
addi a0, zero, 0x55
addi a1, zero, 0xFF
addi sp, zero, 0x700
sb a0, 0(sp)
lb a2, 0(sp)
sb a1, 4(sp)
lb a3, 4(sp)

FAILED 1
