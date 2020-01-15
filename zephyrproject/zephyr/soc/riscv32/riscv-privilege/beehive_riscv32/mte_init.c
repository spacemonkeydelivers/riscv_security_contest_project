#include <init.h>

#include "soc.h"

static void secure_monitor(void* arg)
{
    ARG_UNUSED(arg);
    printk("\n------\nSecure Monitor Panic detected!\n------\n");
    __asm__ __volatile__(
            "li ra, 0xdead\n\t"
            "1:\n\t"
            "j 1b\n\t"
            "wfi\n\t"
            : /* No outputs. */
            :
            : "memory");

}
static int beehive_mte_init(struct device *dev)
{
    ARG_UNUSED(dev);

    IRQ_CONNECT(RISCV_BEEHIVE_SECURE_MONITOR_PANIC_IRQ, 0, secure_monitor, NULL, 0);
    irq_enable(RISCV_BEEHIVE_SECURE_MONITOR_PANIC_IRQ);

    int en_value = 1 | (1 << 3);
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
