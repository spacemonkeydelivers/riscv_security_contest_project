#include <defines.S>
#include <boot.S>

.text
main:
    li a0, TAG_CTRL_ENABLE
    csrw tags, a0

    li t1, TAG_V10
    li t2, TAG_V11

    la a0, __SOC_MEM_SIZE
    addi a0, a0, -4

    // set a tag for an address
    st t1, 0(a0)
    // re-set a tag with another value
    st t2, 0(a0)

    // load tag
    lt t3, 0(a0)

    // expect an updated value to be read
    li t5, TAG_V11
    bne t3, t5, failed

    PASSED

failed:
    FAILED 1

ON_EXCEPTION:
    FAILED 1
