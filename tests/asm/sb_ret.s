#include <defines.S>
#include <boot.S>


.text
main:

    la ra, ret_tgt
    la sp, test_data

    li a0, 0xdeadbee
    sb a0, 3(sp)
    sb a0, 0(sp)
    sb a0, 2(sp)
    sb a0, 1(sp)
    sb a0, 0(sp)
    sb a0, 3(sp)

    ret
    FAILED 1

ret_tgt:
    PASSED

test_data:
    .4byte 0x0

