#include <stdlib.h>
#include <misc/printk.h>

int main () {
    int result = EXIT_SUCCESS;
    printk("printk test!\n");
    printk("printk test result = %d\n", result);
    return result;
}
/*
UART_CHECK:ENABLED
printk test!
printk test result = 0

*/
