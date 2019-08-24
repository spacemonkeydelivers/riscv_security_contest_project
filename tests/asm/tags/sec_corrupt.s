#include <defines.S>
#include <boot.S>

.text
main:
    li a0, TAG_CTRL_ENABLE
    csrw tags, a0

    li t1, TAG_V4
    la a0, tagged1
    st t1, 0(a0)

    li t2, TAG_V5
    // a0 contains incorrectly tagged address
    SET_TAG(a0, t6, t2)

    sb zero, 1(a0)
    FAILED 1

.balign 16
tagged1:
.8byte 0xdeadbeefbeefdead
.8byte 0xbebaddeaddeadbad

ON_EXCEPTION:
    li t1, (TAG_CTRL_ENABLE | TAG_CTRL_IACK)
    csrw tags, t1

    li t2, TAG_V4
    SET_TAG(a0, t6, t2)
    lb t1, 1(a0)
    bne t1, zero, passed
    FAILED 1
passed:
    PASSED
