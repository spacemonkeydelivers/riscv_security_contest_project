#include <setjmp.h>
#define STORE_IDX sw reg, (idx*4)(a0)
#define LOAD_IDX lw reg, (idx*4)(a0)
 

int setjmp(jmp_buf jmp)
{
    __asm__ __volatile__(
           "sw s0, 	(0)(a0)\n\t"
           "sw s1, 	(4)(a0)\n\t"
           "sw s2, 	(8)(a0)\n\t"
           "sw s3, 	(0xc)(a0)\n\t"
           "sw s4, 	(0x10)(a0)\n\t"
           "sw s5, 	(0x14)(a0)\n\t"
           "sw s6, 	(0x18)(a0)\n\t"
           "sw s7, 	(0x1c)(a0)\n\t"
           "sw s8, 	(0x20)(a0)\n\t"
           "sw s9, 	(0x24)(a0)\n\t"
           "sw s10, (0x28)(a0)\n\t"
           "sw s11, (0x2c)(a0)\n\t"
           "sw ra, 	(0x30)(a0)\n\t"
           "sw sp, 	(0x34)(a0)\n\t"
           "li a0, 0\n\t"
           "ret\n\t"
            : /* No outputs. */
            : /* TODO: figure out how to pass *status* to this *ecall* properly */
            : "memory");
//    __builtin_unreachable();
}

void longjmp(jmp_buf jmp, int ret)
{
    __asm__ __volatile__(
           "lw s0, 	(0)(a0)\n\t"
           "lw s1, 	(4)(a0)\n\t"
           "lw s2, 	(8)(a0)\n\t"
           "lw s3, 	(0xc)(a0)\n\t"
           "lw s4, 	(0x10)(a0)\n\t"
           "lw s5, 	(0x14)(a0)\n\t"
           "lw s6, 	(0x18)(a0)\n\t"
           "lw s7, 	(0x1c)(a0)\n\t"
           "lw s8, 	(0x20)(a0)\n\t"
           "lw s9, 	(0x24)(a0)\n\t"
           "lw s10, (0x28)(a0)\n\t"
           "lw s11, (0x2c)(a0)\n\t"
           "lw ra, 	(0x30)(a0)\n\t"
           "lw sp, 	(0x34)(a0)\n\t"
	       "beq a1, zero, 0f\n\t"
	       "mv a0, a1\n\t"
	       "ret\n\t"

	       "0:\n\t"
	       "li a0, 1\n\t"
	       "ret\n\t"
            : /* No outputs. */
            : /* TODO: figure out how to pass *status* to this *ecall* properly */
            : "memory");
 //   __builtin_unreachable();
}
