#include <defines.S>

.section "reset", "awx"
__start:
    add t1, t1, t1
.option push
.option norvc
    j unaligned
    FAILED 1
.option pop

.balign 16
.skip 2
unaligned:
    add t1, t1, t1
.option push
.option norvc
    PASSED
.option pop
