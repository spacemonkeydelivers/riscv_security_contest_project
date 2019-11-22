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
    addi a1, a1, 14 // + 14

    // store tags
    st t1, 0(a0)
    st t2, 0(a1)

    // set tags the addresses we going to use
    SET_TAG(a0, t6, t1)
    SET_TAG(a1, t6, t2)

    li t6, 0xabcdef01

    sw t6, 4(a0)
    sb t6, 1(a1)

    // check results of the stores
    lb t1, 4(a0)
    lw t2, -2(a1)
    li t3, 0x01
    li t4, 0x01baddea
    bne t1, t3, failed
    bne t2, t4, failed

    lw t1, 0(a0)
    lw t1, 4(a0)
    lw t1, 8(a0)
    lw t1, 12(a0)
    // half
    lh t1, 0(a0)
    lh t1, 2(a0)
    lh t1, 4(a0)
    lh t1, 8(a0)
    lh t1, 10(a0)
    lh t1, 12(a0)
    lh t1, 14(a0)
    // bytes
    lb t1, 0(a0)
    lb t1, 2(a0)
    lb t1, 4(a0)
    lb t1, 8(a0)
    lb t1, 10(a0)
    lb t1, 12(a0)
    lb t1, 14(a0)
    lb t1, 1(a0)
    lb t1, 3(a0)
    lb t1, 7(a0)
    lb t1, 9(a0)
    lb t1, 11(a0)
    lb t1, 13(a0)
    lb t1, 15(a0)

    li t1, 0x012345678
    addi a1, a1, 1 // + 15
    sw t1, -3(a1)
    sw t1, -7(a1)
    sw t1, -11(a1)
    sw t1, -15(a1)
    // half
    sh t1, -1(a1)
    sh t1, -3(a1)
    sh t1, -5(a1)
    sh t1, -9(a1)
    sh t1, -11(a1)
    sh t1, -13(a1)
    sh t1, -15(a1)
    // bytes
    sb t1, -1(a1)
    sb t1, -3(a1)
    sb t1, -5(a1)
    sb t1, -9(a1)
    sb t1, -11(a1)
    sb t1, -13(a1)
    sb t1, -15(a1)
    sb t1, -2(a1)
    sb t1, -4(a1)
    sb t1, -6(a1)
    sb t1, -8(a1)
    sb t1, -10(a1)
    sb t1, -12(a1)
    sb t1, -14(a1)
    sb t1, 0(a1)

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
