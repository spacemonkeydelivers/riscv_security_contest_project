#include <defines.S>
#include <boot.S>

.text
main:
    li a0, 0x58800051
    li a6, 0x7F800351

    mulh t1, a0, a6
    mul t3, a0, a6
    li t2, 0x2C13C14D
    li t4, 0xD8010CA1
    bne t2, t1, failed
    bne t3, t4, failed
PASSED

failed:
FAILED 1


