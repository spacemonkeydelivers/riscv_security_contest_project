
#include <misc/printk.h>

void main(void)
{
	printk("Hello from Thales! %s\n", CONFIG_BOARD);
	printf("Hello from Thales! %s\n");
}
