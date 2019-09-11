#include <defines.S>

.section "reset", "awx"
__start:

.option push
.option norvc
    la sp, data
.option pop

    c.lwsp t1, 0(sp)
    c.lwsp t0, 4(sp)

.option push
.option norvc
    li t2, 0xdeadbee
    bne t2, t1, failed
    li t2, 0xdeadbabe
    bne t2, t0, failed
    PASSED
failed:
    FAILED 1
.option pop

.balign 64
data:
.4byte 0xdeadbee
.4byte 0xdeadbabe
