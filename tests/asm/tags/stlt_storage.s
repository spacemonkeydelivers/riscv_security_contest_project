#include <defines.S>
#include <boot.S>

.text
main:
    li a0, TAG_CTRL_ENABLE
    csrw tags, a0

    li t1, TAG_V1
    li t2, TAG_V15

    // load addresses we want to tag
    la a0, tagged1
    la a1, tagged2
    addi a1, a1, 15

    // store tags
    st t1, 0(a0)
    st t2, 0(a1)

    // load stored tags
    lt t3, 0(a1)
    lt t4, 0(a0)

    // self-checking routine starts here
    li t5, TAG_V15
    li t6, TAG_V1
    // if loaded values are not equal to the expected, we fail
    bne t3, t5, failed
    bne t4, t6, failed


    PASSED

failed:
    FAILED 1

.balign 16
tagged1:
.8byte 0xdeadbeefbeefdead
.8byte 0xbaddeaddeadbad
.balign 16
tagged2:
.8byte 0xdeadbeefbeefdead
.8byte 0xbaddeaddeadbad

ON_EXCEPTION:
    FAILED 1
