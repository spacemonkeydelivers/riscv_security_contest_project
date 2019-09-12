#include <defines.S>

.section "reset", "awx"
__start:
.option push
.option norvc
    add t1, t1, t1
.option pop

    c.nop
    c.jal passed
expected_link:
    FAILED 2

.skip 16

.option push
.option norvc
failed:
    FAILED 1
passed:
    la t2, expected_link
    bne t2, ra, failed
    PASSED
.option pop
