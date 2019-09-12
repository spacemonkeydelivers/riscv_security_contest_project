#include <defines.S>

.section "reset", "awx"
__start:

.option push
.option norvc
    la sp, data
    la t1, 0
    la t2, 1
.option pop

    c.swsp t1, 0(sp)
    c.swsp t2, 4(sp)

.option push
.option norvc
    la t2, data
    lw t3, 0(t2)
    lw t4, 4(t2)

    li t1, 0
    bne t1, t3, failed
    li t2, 1
    bne t2, t4, failed
    PASSED
failed:
    FAILED 1
.option pop

.balign 64
data:
.4byte 0xdeadbee
.4byte 0xdeadbabe
