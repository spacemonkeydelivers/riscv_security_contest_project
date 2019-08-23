#include <defines.S>
#include <boot.S>

.text
main:

la sp, test_data

lb ra, 0(sp)
li s0, 1
bne ra, s0, failed

lb ra, 1(sp)
li s0, 2
bne ra, s0, failed

lb ra, 2(sp)
li s0, 3
bne ra, s0, failed

lb ra, 3(sp)
li s0, 4
bne ra, s0, failed


PASSED

failed:
FAILED 1

.align 4
test_data:
.byte 1
.byte 2
.byte 3
.byte 4
