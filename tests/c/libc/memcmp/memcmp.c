#include <stdlib.h>
#include <string.h>
#include <stdio.h>

int main () {
    unsigned char l1 [] = { 0x1, 0x2, 0x3 };
    unsigned char r1 [] = { 0x1, 0x2, 0x3 };

    if (memcmp(l1, r1, 3) != 0) {
        printf("error: l1 is expected to be equal to r1\n");
        return EXIT_FAILURE;
    }

    unsigned char l2 [] = { 0x1, 0x3, 0x3 };
    unsigned char r2 [] = { 0x1, 0x2, 0x3 };
    if (memcmp(l2, r2, 3) != 1) {
        printf("error: l2 is expected to be greater than r2\n");
        return EXIT_FAILURE;
    }

    unsigned char l3 [] = { 0x1, 0x2, 0x3 };
    unsigned char r3 [] = { 0x2, 0x2, 0x3 };
    if (memcmp(l3, r3, 3) != -1) {
        printf("error: l3 is expected to be less than r2\n");
        return EXIT_FAILURE;
    }

    return EXIT_SUCCESS;
}
