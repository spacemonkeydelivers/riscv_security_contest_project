#include <unistd.h>

void _exit(int status)
{
    if (status != 0 ) {
      __asm__ __volatile__(
              "wfi\n\t"
              : /* No outputs. */
              : /* TODO: figure out how to pass *status* to this *ecall* properly */
              : "memory");
    }
    else {
      __asm__ __volatile__(
              "wfi\n\t"
              : /* No outputs. */
              : /* TODO: figure out how to pass *status* to this *ecall* properly */
              : "memory");
    }
    __asm__ __volatile__(".4byte 0xffffffff");
    __builtin_unreachable();
}

