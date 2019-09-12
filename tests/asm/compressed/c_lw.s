#include <defines.S>

.section "reset", "awx"
__start:

.option push
.option norvc
    la a4, data
.option pop

    c.lw a1, 0(a4)
    c.lw a0, 4(a4)

.option push
.option norvc
    li t2, 0xdeadbee
    bne t2, a1, failed
    li t2, 0xdeadbabe
    bne t2, a0, failed
    PASSED
failed:
    FAILED 1
.option pop

.balign 64
data:
.4byte 0xdeadbee
.4byte 0xdeadbabe
