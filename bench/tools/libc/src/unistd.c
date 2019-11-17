#include <unistd.h>

void _exit(int status)
{
    if (status != 0 ) {
      unsigned int ustat = status;
      if (ustat > 256) {
         ustat = 256;
      }
      __asm__ __volatile__(
              "mv ra, %[status]\n\t"
              "li sp, 0\n\t"
              "ecall\n\t"
              "1:\n\t"
              "j 1b\n\t"
              "wfi"
              : /* No outputs. */
              : [status]"r"(status)
              : "memory");
    }
    else {
      __asm__ __volatile__(
              "li ra, 0x0A11C001\n\t"
              "li sp, 0\n\t"
              "ecall\n\t"
              "1:\n\t"
              "j 1b\n\t"
              "wfi\n\t"
              : /* No outputs. */
              :
              : "memory");
    }
    __asm__ __volatile__(".4byte 0xffffffff" ::: "memory");
    __builtin_unreachable();
}

