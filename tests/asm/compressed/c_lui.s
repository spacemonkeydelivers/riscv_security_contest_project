#include <defines.S>

.section "reset", "awx"
__start:

.option push
.option norvc
    li t1, 0x0001f000
    li t3, 0x00001000
.option pop

    c.lui a0, 31
    c.lui a1, 1

.option push
.option norvc
    bne t1, a0, failed
    bne t3, a1, failed
    PASSED
failed:
    FAILED 1
.option pop
