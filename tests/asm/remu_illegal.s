#include "lib/defines.S"

.global __start

.section .reset, "awx"
__start:

    la t1, test_passed
    csrw mtvec, t1
    li a0, 0x0deadbee
    li a6, 0x10
// we expect that remu will trigger ILLEGAL_INSTRUCITON_FAULT
    remu t4, a0, a6
    FAILED 1

.balign 4
test_passed:
// todo: add mcause checks
    PASSED


