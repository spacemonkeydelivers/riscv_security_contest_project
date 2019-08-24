#include <defines.S>
#include <boot.S>

.text
main:
    li a0, (TAG_CTRL_ENABLE | TAG_CTRL_IACK)
    csrw tags, a0

    // a2 contains marker that we visited and interrupt
    li a2, 0
    li t1, TAG_V1
    // load addresses we want to tag
    la a0, tagged1

    // set tags
    st t1, 0(a0)

    // we expect to have tag mismatch here
    sw zero, 0(a0)

bsy_wait:
    li a3, 1
    bne a3, a2, bsy_wait

    PASSED


failed:
    FAILED 1

.balign 16
tagged1:
.8byte 0xdeadbeefbeefdead
.8byte 0xbaddeaddeadbad

ON_EXCEPTION:
    li t1, (TAG_CTRL_ENABLE | TAG_CTRL_IACK)
    csrw tags, t1
    addi a2, a2, 1
    // lw t1, 0(a0)
    // TODO: maybe we should check that memory is left untouched
    mret
