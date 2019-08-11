#include "lib/defines.S"

.global __start

.section .reset, "awx"
__start:

la t0, failed
csrw mtvec, t0 
la sp, test_data

csrr a0, mvendorid
lw a1, 0(sp)

bne a0, a1, failed

PASSED

failed:
FAILED 1

test_data:
.4byte 0xc001f001

