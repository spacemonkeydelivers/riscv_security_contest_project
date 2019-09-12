#include <defines.S>

.section "reset", "awx"
__start:
.option push
.option norvc
    li a0, 1
    li a1, 0
.option pop

    c.nop
    c.beqz a0, failed
    c.beqz a1, passed
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
