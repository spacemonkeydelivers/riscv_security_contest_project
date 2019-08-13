#include <generated/esf.h>
# temporary include till we have a proper implementation
#include <rtlsim/soc_enums.h>
#include <soc/traps.h>

.global __isr_wrapper

.section ".__system.isr", "ax"
.balign 4
__isr_wrapper:
    addi sp, sp, -__ESF_STRUCTURE_SIZE
    __D_PUSH_GPR2ESF

    # align stack pointer
    mv t1, sp
    addi t1, t1, 16
    li t2, 0xf
    not t2, t2
    and t1, t1, t2
    # save previous (possibly unaligned) sp value
    sw sp, 0(t1)
    # s0 points to an original ESF structure
    mv a0, sp
    mv sp, t1

#ifdef __SOC_IS_NOT_SYSTEM_CONFORMANT
    csrr a1, mcause
    li t2, EN_MCAUSE_EXTERNAL_INTERRUPT
    beq a1, t2, interrupt
exception:
    # in case of exceptions a1 contains mcause which is compatible with the spec
    call __exc_serve
    j restore
interrupt:
    li a1, EN_ASM_RISCV_INT_EXT_M
    call __int_serve
#else
    .error "isr routing for conformant core is not implemented"
#endif

restore:
    lw sp, 0(sp)
    __D_POP_ESF2GPR
    addi sp, sp, __ESF_STRUCTURE_SIZE
    mret
    wfi
