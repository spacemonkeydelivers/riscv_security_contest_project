#include <stdlib.h>

#include <soc/traps.h>
#include <soc/timer.h>

volatile int global = 0;
volatile int unused = 0;

void timer_handler(int n, void* context)
{
    global = 1;

    alarm_soc_timer(0);
}

int main () {
    global = 0;
    unused = 0;
    register_int_handler(RISCV_INT_EXT_M, &timer_handler);

    if (!alarm_soc_timer(100)) {
        return EXIT_FAILURE;
    }

    while (global == 0)
    {
        ++unused;
    }
    return EXIT_SUCCESS;
}

