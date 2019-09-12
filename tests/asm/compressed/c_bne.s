#include <defines.S>

.section "reset", "awx"
__start:
.option push
.option norvc
    li a0, 0
    li a1, 1
.option pop

    c.nop
    c.bnez a0, failed
    c.bnez a1, passed
    c.nop
    FAILED 2

.skip 16

.option push
.option norvc
failed:
    FAILED 1
passed:
    bne ra, zero, failed
    PASSED
.option pop
