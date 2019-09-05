#include <kernel.h>
#include <arch/cpu.h>
#include <uart.h>
#include <sys_io.h>
#include <board.h>

#define DEV_CFG(dev)                    \
    ((const struct uart_device_config * const)  \
     (dev)->config->config_info)

static void uart_beehive_poll_out(struct device *dev, unsigned char c)
{
    sys_write8(c, DEV_CFG(dev)->regs);
    return;
}

static int uart_beehive_poll_in(struct device *dev, unsigned char *c)
{
    /* Nothing to do */

    return 0;
}

static int uart_beehive_init(struct device *dev)
{
    /* Nothing to do */

    return 0;
}


static const struct uart_driver_api uart_beehive_driver_api = {
    .poll_in = uart_beehive_poll_in,
    .poll_out = uart_beehive_poll_out,
    .err_check = NULL,
};

static const struct uart_device_config uart_beehive_dev_cfg_0 = {
    .regs = RISCV_BEEHIVE_UART_BASE,
};


DEVICE_AND_API_INIT(uart_beehive_0, CONFIG_UART_BEEHIVE_PORT_0_NAME,
            uart_beehive_init, NULL,
            &uart_beehive_dev_cfg_0,
            PRE_KERNEL_1, CONFIG_KERNEL_INIT_PRIORITY_DEVICE,
            (void *)&uart_beehive_driver_api);
