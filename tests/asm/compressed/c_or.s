#include <defines.S>

.section "reset", "awx"
__start:

.option push
.option norvc
    li a1, 0x101
    li a2, 0x10001011
.option pop

    c.or a1, a2

.option push
.option norvc
    li t2, 0x10001111
    bne t2, a1, failed
    PASSED
failed:
    FAILED 1
.option pop
