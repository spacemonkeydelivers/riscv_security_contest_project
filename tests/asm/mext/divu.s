#include <defines.S>
#include <boot.S>

.text
main:
    li a0, 0x11111
    li a6, 0x12

    divu t1, a0, a6
    li t2, 0xF2B
    bne t1, t2, failed

    li a0, 0xFFFFFFFA
    li a6, 0x3

    divu t1, a0, a6
    li t2, 0x55555553
    bne t1, t2, failed
PASSED

failed:
FAILED 1



