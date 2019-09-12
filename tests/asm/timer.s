#include <defines.S>
#include <boot.S>

.text
main:
mv sp, zero
lui sp, 0x40000
// count clocks
addi a0, zero, 1
sw a0, 16(sp)
// up to 10 clocks
addi a0, zero, 5
sb a0, 8(sp)
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

ON_EXCEPTION:
mv zero, zero
mv zero, zero
mv zero, zero
sb a0, 8(sp)
    PASSED
