#include <defines.S>

.section "reset", "awx"
__start:

.option push
.option norvc
    li sp, 0x7fffffff
.option pop

    // adds sign-extended imm to sp and writes to dst
    c.addi4spn a1, sp, 0x3fc
    c.addi4spn a2, sp, 0x1fc

.option push
.option norvc
    li t3, 0x800003fb
    li t4, 0x800005f7
    bne a1, t3, failed
    bne a2, t2, failed
    PASSED
failed:
    FAILED 1
.option pop
