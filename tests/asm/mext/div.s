#include <defines.S>
#include <boot.S>

.text
main:
    li a0, 0x11111
    li a6, 0x12

    div t1, a0, a6
    li t2, 0xF2B
    bne t1, t2, failed

    li a0, 0xFFFFFFFA
    li a6, 0x3

    div t1, a0, a6
    li t2, 0xFFFFFFFE
    bne t1, t2, failed

    li a0, 0x1
    li a1, -0x1
    li a2, 0xFFFFFFFF

    div t1, a0, a2
    li t2, 0xFFFFFFFF
    bne t2, t1, failed
    //li t3,
    
    //li t2, 0xFFFFFFFF
    //bne t2, a1, failed
    /*div t1, a0, a1
    li t2, 0xFFFFFFFF
    bne t1, t2, failed*/

PASSED

failed:
FAILED 1


