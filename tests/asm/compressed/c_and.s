#include <defines.S>

.section "reset", "awx"
__start:

.option push
.option norvc
    li a4, 0x101
    li a5, 0x10001011
.option pop

    c.and a4, a5

.option push
.option norvc
    li t2, 0x1
    bne t2, a4, failed
    PASSED
failed:
    FAILED 1
.option pop
