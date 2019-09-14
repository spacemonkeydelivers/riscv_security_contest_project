#include <stdio.h>
#include <stdlib.h>

int main () {
    printf("Behold! 16 bytes are allocated!");
    volatile char* ptr = malloc(16);
    ptr[0] = 'H';
    ptr[1] = 'e';
    ptr[2] = 'l';
    ptr[3] = 'l';
    ptr[4] = 'o';
    ptr[5] = '\n';
    ptr[6] = 0;
    printf("msg1: %s", ptr);
    ptr[17] = 0;
    printf("msg2: %s", ptr);
    exit(1);
    return 0;
}
