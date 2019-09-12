#include <defines.S>

.section "reset", "awx"
__start:

.option push
.option norvc
    li t1, 2
    li t3, -1
.option pop

    c.li a0, 2
    c.li a1, -1

.option push
.option norvc
    bne t1, a0, failed
    bne t3, a1, failed
    PASSED
failed:
    FAILED 1
.option pop
