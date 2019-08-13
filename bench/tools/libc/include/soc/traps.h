#ifndef __INCLUDE_GUARD_RISCV_TRAPS__
#define __INCLUDE_GUARD_RISCV_TRAPS__

#define EN_ASM_RISCV_INT_EXT_M 11

#define D_SOC_INTERRUPTS \
    D_ENUM_ENTRY(RISCV_INT_SI_U, "User software interrupt", 0) \
    D_ENUM_ENTRY(RISCV_INT_SI_S, "Supervisor software interrupt", 1) \
    D_ENUM_ENTRY(RISCV_INT_RSVD1, "Reserved", 2) \
    D_ENUM_ENTRY(RISCV_INT_SI_M, "Machine software interrupt", 3) \
    D_ENUM_ENTRY(RISCV_INT_TIMER_U, "User timer interrupt", 4) \
    D_ENUM_ENTRY(RISCV_INT_TIMER_S, "Supervisor timer interrupt", 5) \
    D_ENUM_ENTRY(RISCV_INT_RSVD2, "Reserved", 6) \
    D_ENUM_ENTRY(RISCV_INT_TIMER_M, "Machine timer interrupt", 7) \
    D_ENUM_ENTRY(RISCV_INT_EXT_U, "User external interrupt", 8) \
    D_ENUM_ENTRY(RISCV_INT_EXT_S, "Supervisor external interrupt", 9) \
    D_ENUM_ENTRY(RISCV_INT_RSVD3, "Reserved", 10) \
    D_ENUM_ENTRY(RISCV_INT_EXT_M, "Machine external interrupt", EN_ASM_RISCV_INT_EXT_M) \
    D_ENUM_ENTRY(RISCV_INT_TOTAL, "TOTAL", 12) \

#define D_SOC_EXCEPTIONS \
    D_ENUM_ENTRY(RISCV_EXC_I_ALIGN, "Instruction address misaligned", 0) \
    D_ENUM_ENTRY(RISCV_EXC_I_AFAULT, "Instruction access fault", 1) \
    D_ENUM_ENTRY(RISCV_EXC_ILLEGAL, "Illegal instruction", 2) \
    D_ENUM_ENTRY(RISCV_EXC_BRK, "Breakpoint", 3) \
    D_ENUM_ENTRY(RISCV_EXC_DL_ALIGN, "Load address misaligned", 4) \
    D_ENUM_ENTRY(RISCV_EXC_DL_AFAULT, "Load access fault", 5) \
    D_ENUM_ENTRY(RISCV_EXC_DS_ALIGN, "Store/AMO address misaligned", 6) \
    D_ENUM_ENTRY(RISCV_EXC_DS_AFAULT, "Store/AMO access fault", 7) \
    D_ENUM_ENTRY(RISCV_EXC_U2ENV, "Environment call from U-mode", 8) \
    D_ENUM_ENTRY(RISCV_EXC_S2ENV, "Environment call from S-mode", 9) \
    D_ENUM_ENTRY(RISCV_EXC_RSVD1, "Reserved", 10) \
    D_ENUM_ENTRY(RISCV_EXC_M2ENV, "Environment call from M-mode", 11) \
    D_ENUM_ENTRY(RISCV_EXC_I_PAGE, "Instruction page fault", 12) \
    D_ENUM_ENTRY(RISCV_EXC_DL_PAGE, "Load page fault", 13) \
    D_ENUM_ENTRY(RISCV_EXC_RSVD2, "Reserved", 14) \
    D_ENUM_ENTRY(RISCV_EXC_DS_PAGE, "Store/AMO page fault", 15) \
    D_ENUM_ENTRY(RISCV_EXC_TOTAL, "TOTAL", 16)

#ifndef __ASSEMBLER__

#define D_ENUM_ENTRY(entry, str, value) entry = value,
enum SOC_INT
{
    D_SOC_INTERRUPTS
};
enum SOC_EXC
{
    D_SOC_EXCEPTIONS
};
#undef D_ENUM_ENTRY

typedef void (*exc_handler_t)(int exc, void* context);
typedef void (*int_handler_t)(int n, void* context);

exc_handler_t register_exc_handler(int exc, exc_handler_t);
int_handler_t register_int_handler(int n, int_handler_t);

#endif // __ASSEMBLER__

#endif /* end of include guard: __INCLUDE_GUARD_RISCV_TRAPS__ */

