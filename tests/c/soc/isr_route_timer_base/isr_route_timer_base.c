#include <stdlib.h>
#include <stdio.h>

#include <soc/traps.h>
#include <soc/timer.h>

volatile int global = 0;
volatile int unused = 0;

#define D_TIMEOUT 9000
void timer_handler(int n, void* context)
{
    (void)context;
    if (n != RISCV_INT_TIMER_M) {
        printf("\nERROR: interrupt number is not correct!\n");
        exit(42);
    }
    ++global;

    if (global < 10) {
        alarm_soc_timer(D_TIMEOUT);
    } else {
        // To stop timer interrupts
        alarm_soc_timer_stop();
    }
}

int main () {
    register_int_handler(RISCV_INT_TIMER_M, &timer_handler);

    if (!alarm_soc_timer(D_TIMEOUT)) {
        return EXIT_FAILURE;
    }

    while (global < 10)
    {
        ++unused;
    }
    printf("unused value: %d\n", unused);
    return EXIT_SUCCESS;
}

