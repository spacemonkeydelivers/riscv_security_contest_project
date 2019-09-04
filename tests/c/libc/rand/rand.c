#include <soc/traps.h>
#include <stdlib.h>
#include <stdio.h>

int main () {
    unsigned int* ptr = (unsigned int*)malloc(50 * sizeof(unsigned int));
    for (int i = 0; i < 50; i++)
        ptr[i] = rand();

    unsigned count = 0;
    for (int i = 0; i < 49; i++)
        for (int j = i + 1; j < 50; j++)
            if (ptr[i] == ptr[j]) count = count + 1;

    // assuming less than 5% chance to have repeated value
    if (count < 3) return EXIT_SUCCESS;
    return EXIT_FAILURE;
}
