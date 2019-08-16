#include <stdlib.h>

#include <soc/traps.h>
#include <soc/timer.h>

void ialign_handler(int n, void* context)
{
    exit(0);
}

int main () {
    register_int_handler(RISCV_EXC_I_ALIGN, &ialign_handler);
    __asm__ volatile ("li ra, 2\n"
                      "ret"
                      :
                      :
                      : "memory");
    return EXIT_FAILURE;
}

