#include <defines.S>

.section "reset", "awx"
__start:

.option push
.option norvc
    li t1, 1
    li t3, 1
.option pop

    add t1, t1, t1
    add t1, t1, t1

    add t3, t3, t1
    add t3, t3, t1

.option push
.option norvc
    li t2, 4
    bne t2, t1, failed
    li t2, 9
    bne t3, t2, failed
    PASSED
failed:
    FAILED 1
.option pop
