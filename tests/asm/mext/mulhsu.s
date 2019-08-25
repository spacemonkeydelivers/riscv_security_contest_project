#include <defines.S>
#include <boot.S>

.text
main:
    li a0, 0x5
    li a6, 0x6

    sub t3, zero, a0
    //li t2, 0xFFFFFFFB
    //beq t2, t3, passed

    mulhsu t1, t3, a6

    li t2, 0xFFFFFFFF
    bne t2, t1, failed

passed:
PASSED

failed:
FAILED 1


