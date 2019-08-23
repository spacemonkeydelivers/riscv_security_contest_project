#include <defines.S>
#include <boot.S>

.text
main:
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
ON_EXCEPTION:
PASSED
