#include "lib/defines.S"

.global __start

.section .reset, "awx"
__start:


li a0, 0x0000FFFF
li a1, 0xFFFF0000
li a2, 0x33333333
li a3, 0xFFFF3333

csrw mscratch, a2
csrrs a4, mscratch, a1
csrr a5, mscratch

bne a5, a3, failed


PASSED

failed:
FAILED 1
