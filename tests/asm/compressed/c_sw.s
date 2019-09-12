#include <defines.S>

.section "reset", "awx"
__start:

.option push
.option norvc
    la a4, data
    la a1, 0xaaaaaaaa
    la a2, 1
.option pop

    c.sw a1, 0(a4)
    c.sw a2, 4(a4)

.option push
.option norvc
    la t2, data
    lw t3, 0(t2)
    lw t4, 4(t2)

    li t1, 0xaaaaaaaa
    bne a1, t3, failed
    li t2, 1
    bne a2, t4, failed
    PASSED
failed:
    FAILED 1
.option pop

.balign 64
data:
.4byte 0xdeadbee
.4byte 0xdeadbabe
