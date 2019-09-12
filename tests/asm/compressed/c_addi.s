#include <defines.S>

.section "reset", "awx"
__start:

.option push
.option norvc
    li a0, 1
    li a2, 15
.option pop

    c.addi a0, 1
    c.addi a2, 15

.option push
.option norvc
    li t2, 2
    bne t2, a0, failed
    li t2, 30
    bne t2, a2, failed
    PASSED
failed:
    FAILED 1
.option pop
