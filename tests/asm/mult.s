#include <defines.S>
#include <boot.S>

.text
main:
    li a0, 0x12
    li a6, 0x3F
    //li a0, 1
    //li a6, 1
    mul t1, a0, a6
    //add t1, a0, a6
    li t2, 0x46E
    //li t2, 0x2
    bne t2, t1, failed
PASSED

failed:
FAILED 1


