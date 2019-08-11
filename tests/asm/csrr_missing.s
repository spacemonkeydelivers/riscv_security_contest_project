#include "lib/defines.S"

.global __start

.section .reset, "awx"
__start:

la t0, failed
csrw mtvec, t0 

csrr a0, pmpaddr15

FAILED 1

failed:
PASSED

