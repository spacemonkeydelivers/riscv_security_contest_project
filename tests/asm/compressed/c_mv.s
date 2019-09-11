#include <defines.S>

.section "reset", "awx"
__start:

.option push
.option norvc
    li t1, 55
    li t3, 4
.option pop

    c.mv t3, t1
    c.mv t2, t3

.option push
.option norvc
    li t4, 55
    bne t3, t4, failed
    bne t2, t4, failed
    PASSED
failed:
    FAILED 1
.option pop
