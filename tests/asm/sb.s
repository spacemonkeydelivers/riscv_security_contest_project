#include <defines.S>
#include <boot.S>

.text
main:
la sp, test_data

li a0, 1
sb a0, 0(sp)

li a0, 2
sb a0, 1(sp)

li a0, 3
sb a0, 2(sp)

li a0, 4
sb a0, 3(sp)


lw a0, 0(sp)
li t1, 0x04030201

bne a0, t1, failed

PASSED

failed:
FAILED 1

.balign 4
test_data:
.4byte 0x0

