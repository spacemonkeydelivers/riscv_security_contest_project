#include <defines.S>

.section "reset", "awx"
__start:

.option push
.option norvc
    li t1, 1
.option pop

    c.slli t1, 3

.option push
.option norvc
    li t2, 8
    bne t2, t1, failed
    PASSED
failed:
    FAILED 1
.option pop
