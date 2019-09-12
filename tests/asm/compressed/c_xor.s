#include <defines.S>

.section "reset", "awx"
__start:

.option push
.option norvc
    li a1, 0x101
    li a5, 0x10001011
.option pop

    c.xor a5, a1

.option push
.option norvc
    li t2, 0x10001110
    bne t2, a5, failed
    PASSED
failed:
    FAILED 1
.option pop
