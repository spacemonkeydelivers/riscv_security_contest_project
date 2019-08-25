#include <defines.S>
#include <boot.S>

.text
main:
    li a0, 0x11111
    li a6, 0x12

    remu t1, a0, a6
    li t2, 0xB
    bne t1, t2, failed

    /*sub t3, zero, a0
    remu t1, t3, a6
    li t2, 0xFFFFFFF5
    bne t1, t2, failed*/
PASSED

failed:
FAILED 1


