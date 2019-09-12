#include <defines.S>

.section "reset", "awx"
__start:
.option push
.option norvc
    add t1, t1, t1
    mv ra, zero
.option pop

    c.nop
    c.j passed
expected_link:
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
