#include <soc/traps.h>
#include <stdlib.h>
#include <stdio.h>


int main () {
    unsigned char* ptr1 = (unsigned char*)malloc(64);
    unsigned char* ptr2 = (unsigned char*)malloc(64);
    for (int i = 0; i < 64; ++i) {
        ptr1[i] = 64 - i;
        ptr2[i] = i;
    }
    if (ptr1[32] + ptr2[32] == 64) {
        return EXIT_SUCCESS;
    }
    return EXIT_FAILURE;
}
