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

/* SECURITY_CTRL: DISABLE */
int main () {

    register_int_handler(RISCV_INT_SM_PANIC, &secure_monitor);

    unsigned char* ptr = (unsigned char*)malloc(64);
    if (ptr) {
        for (int i = 0; i < 64; ++i) {
            ptr[i] = i;
        }
        ptr[65] = 0; // no security, no boom :(
        return EXIT_SUCCESS;
    }
    return EXIT_FAILURE;
}
