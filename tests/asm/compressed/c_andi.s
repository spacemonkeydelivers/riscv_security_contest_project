#include <defines.S>

.section "reset", "awx"
__start:

.option push
.option norvc
    li a5, 0xffffff0f
.option pop

    c.andi a5, 0x1a

.option push
.option norvc
    li t2, 0xa
    bne t2, a5, failed
    PASSED
failed:
    FAILED 1
.option pop
