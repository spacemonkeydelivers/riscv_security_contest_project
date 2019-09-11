#include <defines.S>

.section "reset", "awx"
__start:
.option push
.option norvc
    add t1, t1, t1
    la t1, passed
.option pop

    c.nop
    c.jr t1

.skip 16

.option push
    FAILED 1
.option norvc
passed:
    PASSED
.option pop
