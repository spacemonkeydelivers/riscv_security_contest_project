#include <defines.S>
#include <boot.S>

.text
main:
    li a0, TAG_CTRL_ENABLE
    csrw tags, a0

    li t1, TAG_V2

    // load addresses we want to tag
    la a0, tagged1
    la sp, tagged1

    // store tags
    st t1, 0(a0)

    // set tags the addresses we going to use
    SET_TAG(a0, t6, t1)


    sw t6, 4(a0)
    sw t6, 4(sp)

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
