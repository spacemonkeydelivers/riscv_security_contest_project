#include <defines.S>
#include <boot.S>

.text
main:
li a0, 0x11111111
li a1, 0xCCCCCCCC
li a2, 0x33333333

csrw mscratch, a0
csrrw a2, mscratch, a1

bne a0, a2, failed


PASSED

failed:
FAILED 1
