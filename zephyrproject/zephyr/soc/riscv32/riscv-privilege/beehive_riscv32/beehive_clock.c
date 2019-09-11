#include <init.h>

#include "soc.h"

static int beehive_clock_init(struct device *dev) 
{
    ARG_UNUSED(dev);

    volatile u32_t *r = (u32_t *)BEEHIVE_MTIMECTRL_BASE;
    u64_t freq = 4;  // to lower freq

    r[1] = (u32_t)(freq >> 32);
    r[0] = (u32_t)freq;

    return 0;
}

SYS_INIT(beehive_clock_init,
         PRE_KERNEL_1,
         CONFIG_BEEHIVE_TIMER_INIT_PRIORITY);
