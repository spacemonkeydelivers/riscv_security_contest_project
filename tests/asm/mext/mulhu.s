#include <defines.S>
#include <boot.S>

.text
main:
    li a0, 0xF0000000
    li a6, 0xF0000000

    mulhu t1, a0, a6
    li t2, 0xE1000000
    bne t2, t1, failed
PASSED

failed:
FAILED 1


