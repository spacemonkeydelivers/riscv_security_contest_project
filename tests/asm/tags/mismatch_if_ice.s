#include <defines.S>
#include <boot.S>

.text
main:
    li t1, (TAG_CTRL_ENABLE | TAG_CTRL_ICHECK_ENABLE)
    csrw tags, t1

    // set tag
    la a0, tagged
    li t1, TAG_V7
    st t1, 0(a0)
    // we attempt to branch to a tagged area
    j tagged

.balign 16
tagged:
    nop
    add t1, t1, t1
    FAILED 1


ON_EXCEPTION:
    PASSED
