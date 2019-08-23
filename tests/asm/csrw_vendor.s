#include <defines.S>
#include <boot.S>


.text
main:
    csrw mvendorid, zero
    lw a1, 0(sp)

    FAILED 1

.balign 4
ON_EXCEPTION:
    PASSED

