#include "lib/defines.S"

.global __start

.section .reset, "awx"
__start:

    li a0, 0x0deadbee
    li a6, 0x10
    remu t4, a0, a6
    li t2, 0xe
    bne t2, t4, failed
    PASSED

failed:
    FAILED 1


