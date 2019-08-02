#include "lib/basic.S"

.global __start

.section .reset, "awx"
__start:
mv sp, zero
lui sp, 0x40000
addi a0, zero, 10
sb a0, 0(sp)
mv zero, zero
mv zero, zero
mv zero, zero
mv zero, zero
mv zero, zero
mv zero, zero
lb a0, 0(sp)

FAILED 1
