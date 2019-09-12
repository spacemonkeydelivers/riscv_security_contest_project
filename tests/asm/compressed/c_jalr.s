#include <defines.S>

.section "reset", "awx"
__start:
.option push
.option norvc
    add t1, t1, t1
    la t1, passed
.option pop

    c.nop
    c.jalr t1
expected_link:

.skip 16

.option push
failed:
    FAILED 1
.option norvc
passed:
    la t2, expected_link
    bne t2, ra, failed
    PASSED
.option pop
