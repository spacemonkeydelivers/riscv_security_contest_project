#include "lib/defines.S"

.global __start

.section .reset, "awx"
__start:
addi a3, zero, 1
csrw mstatus, a3
la t1, test_passed
csrw mtvec, t1
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
sb zero, 1(sp)
mv zero, zero
mv zero, zero
mv zero, zero

FAILED 1

.balign 4
test_passed:
PASSED
