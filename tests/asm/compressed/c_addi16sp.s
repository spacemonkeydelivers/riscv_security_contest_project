#include <defines.S>

.section "reset", "awx"
__start:

.option push
.option norvc
    li sp, 0x7fffffff
.option pop

    c.addi16sp sp, -512
    mv t1, sp
    c.addi16sp sp, 496
    mv t2, sp

.option push
.option norvc
    li t3, 0x7ffffdff
    li t4, 0x7fffffef
    bne t1, t3, failed
    bne t4, t2, failed
    PASSED
failed:
    FAILED 1
.option pop
