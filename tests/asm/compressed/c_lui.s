#include <defines.S>

.section "reset", "awx"
__start:

.option push
.option norvc
    li a0, 0xaaaaaaaa
    li a1, 0xbbbbbbbb
    li t1, 0xfffff000
    li t3, 0x00001000
.option pop

    // well... don't ask. see https://github.com/riscv/riscv-tools/issues/182
    c.lui a0, (1<<20) - 1
    c.lui a1, 1

.option push
.option norvc
    bne t1, a0, failed
    bne t3, a1, failed
    PASSED
failed:
    FAILED 1
.option pop
