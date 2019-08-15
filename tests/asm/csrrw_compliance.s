#include "lib/defines.S"

.global __start

.section .reset, "awx"
__start:


li a0, 0x11111111
li a1, 0xCCCCCCCC
li a2, 0x33333333

csrw mscratch, a0
csrrw a2, mscratch, a1

bne a0, a2, failed


PASSED

failed:
FAILED 1
