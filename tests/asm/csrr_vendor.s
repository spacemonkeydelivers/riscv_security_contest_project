#include <defines.S>
#include <boot.S>

.text
main:

    la sp, test_data

    csrr a0, mvendorid
    lw a1, 0(sp)

    bne a0, a1, failed

    PASSED

.balign 4
failed:
ON_EXCEPTION:
    FAILED 1

test_data:
.4byte 0xc001f001

