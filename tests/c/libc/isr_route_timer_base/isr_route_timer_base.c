#include <stdlib.h>
#include <stdio.h>

#include <soc/traps.h>
#include <soc/timer.h>

volatile int global = 0;
volatile int unused = 0;

#define D_TIMEOUT 30
void timer_handler(int n, void* context)
{
    ++global;

    if (global < 100) {
        alarm_soc_timer(D_TIMEOUT);
    } else {
        alarm_soc_timer(0);
    }
}

int main () {
    register_int_handler(RISCV_INT_EXT_M, &timer_handler);

    if (!alarm_soc_timer(D_TIMEOUT)) {
        return EXIT_FAILURE;
    }

    while (global < 100)
    {
        ++unused;
    }
    printf("unused value: %d\n", unused);
    return EXIT_SUCCESS;
}

