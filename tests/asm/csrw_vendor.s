#include "lib/defines.S"

.global __start

.section .reset, "awx"
__start:

la t0, failed
csrw mtvec, t0 

csrw mvendorid, zero
lw a1, 0(sp)

FAILED 1

failed:
PASSED

