#include "lib/defines.S"

.global __start

.section .reset, "awx"
__start:

la t1, handler
csrw mtvec, t1
li t2, 8
csrw mstatus, 8

li sp, 0x1000
li a0, 4
li a2, 5
li a5, 1
csrw tags, a5

st a0, 0(sp)
lt a1, 0(sp)
bne a0, a1, failed

st a2, 16(sp)
lt a1, 16(sp)
bne a2, a1, failed

st a0, 18(sp)
lt a1, 18(sp)
bne a0, a1, failed

li a0, 0xf
st a0, 0(sp)
li sp, 0x3c000000
lw a3, 0(sp)

li a0, 0xe
st a0, 0(sp)
lw a3, 0(sp)

PASSED

failed:
FAILED 1

handler:
li t2, 3
csrw tags, t2
mret

.align 4
test_data:
.byte 1
.byte 2
.byte 3
.byte 4
