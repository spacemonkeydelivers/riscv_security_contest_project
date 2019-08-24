#include <defines.S>
#include <boot.S>

.text
main:
    li a0, TAG_CTRL_ENABLE
    csrw tags, a0

    li t1, TAG_V2
    la a0, tagged1
    st t1, 0(a0)

    li t2, TAG_V10
    // a0 contains incorrectly tagged address
    SET_TAG(a0, t6, t2)

    li a1, 0
    lbu a1, 1(a0)
    FAILED 1

.balign 16
tagged1:
.8byte 0xdeadbeefbeefdead
.8byte 0xbebaddeaddeadbad

ON_EXCEPTION:
    li t1, (TAG_CTRL_ENABLE | TAG_CTRL_IACK)
    csrw tags, t1

    li t1, 0xde
    bne t1, a1, passed
    FAILED 1
passed:
    PASSED
