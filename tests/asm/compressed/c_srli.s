#include <defines.S>

.section "reset", "awx"
__start:

.option push
.option norvc
    li a3, 0xfffffffe
.option pop

    c.srli a3, 1
.option push
.option norvc
    li t2, 0x7fffffff
    bne t2, a3, failed
    PASSED
failed:
    FAILED 1
.option pop
