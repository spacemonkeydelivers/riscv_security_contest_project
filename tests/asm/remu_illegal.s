#include <defines.S>
#include <boot.S>

.text
main:
    li a0, 0x0deadbee
    li a6, 0x10
// we expect that remu will trigger ILLEGAL_INSTRUCITON_FAULT
    remu t4, a0, a6
    FAILED 1

.balign 4
ON_EXCEPTION:
// todo: add mcause checks
    PASSED


