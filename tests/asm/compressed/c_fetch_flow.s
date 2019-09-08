#include <defines.S>

.section "reset", "awx"
__start:
    add t1, t1, t1
.option push
.option norvc
    add t1, t1, t1
.option pop
    nop
    nop
    nop
.option push
.option norvc
    PASSED
.option pop
