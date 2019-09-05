#include <stdlib.h>

#include <soc/traps.h>
#include <soc/timer.h>

void ialign_handler(int n, void* context)
{
    (void)context;
    if (n == RISCV_EXC_I_ALIGN) {
        exit(EXIT_SUCCESS);
    }
    exit(EXIT_FAILURE);
}

int main () {
    register_exc_handler(RISCV_EXC_I_ALIGN, &ialign_handler);
    __asm__ volatile ("li ra, 2\n"
                      "ret"
                      :
                      :
                      : "memory");
    return EXIT_FAILURE;
}

