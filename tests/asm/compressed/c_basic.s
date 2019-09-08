#include <defines.S>

.section "reset", "awx"
__start:
    add t1, t1, t1
.option push
.option norvc
    nop
.option pop

.option push
.option norvc
    PASSED
.option pop
