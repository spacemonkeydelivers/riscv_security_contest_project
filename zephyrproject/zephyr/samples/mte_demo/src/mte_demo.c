#include <zephyr.h>
#include <misc/printk.h>

int main () {
    printk("Behold! 16 bytes are allocated!\n");
    volatile char* ptr = malloc(16);
    ptr[0] = 'H';
    ptr[1] = 'e';
    ptr[2] = 'l';
    ptr[3] = 'l';
    ptr[4] = 'o';
    ptr[5] = '\n';
    ptr[6] = 0;
    printk("msg1: %s\n", ptr);
    ptr[17] = 0;
    printk("msg2: %s\n", ptr);
    exit(1);
    return 0;
}
