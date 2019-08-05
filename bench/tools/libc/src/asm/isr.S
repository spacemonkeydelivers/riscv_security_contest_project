#include <generated/esf.h>

.global __isr_wrapper

.section ".__system.isr", "ax"
.balign 4
__isr_wrapper:
    addi sp, sp, -__ESF_STRUCTURE_SIZE
    __D_PUSH_GPR2ESF

    __D_POP_ESF2GPR
    addi sp, sp, __ESF_STRUCTURE_SIZE
    mret
    wfi
