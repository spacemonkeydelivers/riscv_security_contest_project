#include <defines.S>

.section "reset", "awx"
__start:

.option push
.option norvc
    li a2, 0xfffffffe
.option pop

    c.srai a2, 1

.option push
.option norvc
    li t2, 0xffffffff
    bne t2, a2, failed
    PASSED
failed:
    FAILED 1
.option pop
