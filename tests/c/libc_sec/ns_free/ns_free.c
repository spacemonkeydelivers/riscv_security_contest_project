#include <soc/traps.h>
#include <stdlib.h>
#include <stdio.h>


void secure_monitor(int n, void* context)
{
    if (n == RISCV_INT_SM_PANIC) {
        printf("security panic detected! Test Failure!\n");
        exit(EXIT_FAILURE);
    }
}

int main () {

    register_int_handler(RISCV_INT_SM_PANIC, &secure_monitor);

    unsigned char* ptr = (unsigned char*)malloc(64);
    free(ptr);
    ptr[0] = 0xff;
    return EXIT_SUCCESS;
}
