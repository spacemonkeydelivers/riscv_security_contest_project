#include <init.h>

#include "soc.h"

static int beehive_mte_init(struct device *dev)
{
    ARG_UNUSED(dev);

    int en_value = 0;
    __asm__ __volatile__(
            "csrw tags, %[en_value]"
            :
            : [en_value]"r" (en_value)
            : "memory");
    return 0;
}

SYS_INIT(beehive_mte_init,
         PRE_KERNEL_1,
         true);
