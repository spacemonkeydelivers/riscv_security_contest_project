#include <soc/traps.h>
#include <stdlib.h>
#include <stdbool.h>
#include <stdio.h>

bool test_unique(size_t INUM) {

    if (INUM % 5) {
        printf("test_unique: FAILED. INUM should be divisible by 5");
        return false;
    }

    unsigned int* ptr = malloc(INUM * sizeof(unsigned int));
    for (int i = 0; i < INUM; i++)
        ptr[i] = rand();

    unsigned count = 0;
    for (int i = 0; i < INUM - 1; i++)
        for (int j = i + 1; j < INUM; j++)
            if (ptr[i] == ptr[j]) count = count + 1;

    printf("test_unique dump:\n");
    for (int i = 0; i < INUM; i+=5) {
        printf("%08x %08x %08x %08x %08x\n",
               ptr[i + 0], ptr[i + 1], ptr[i + 2], ptr[i + 3], ptr[i + 4]);
    }
    // assuming less than 5% chance to have repeated value
    if (count > 2) {
        printf("test_unique: FAILED. too many duplicates are detected");
        return false;
    }
    free(ptr);

    return true;
}
bool test_pseudo_distrib(size_t INUM) {

    if (INUM % 10) {
        printf("test_pseudo_distrib: FAILED. INUM should be divisible by 10");
        return false;
    }

    unsigned char* p = malloc(INUM * sizeof(unsigned char));
    for (int i = 0; i < INUM; ++i) {
        p[i] = rand() & 0xf;
    }
    printf("test_pseudo_distrib dump:\n");
    for (int i = 0; i < INUM; i+= 10) {
        printf("%01x %01x %01x %01x %01x %01x %01x %01x %01x %01x\n",
               p[i + 0], p[i + 1], p[i + 2], p[i + 3], p[i + 4],
               p[i + 5], p[i + 6], p[i + 7], p[i + 8], p[i + 9]);
    }
    for (unsigned i = 0; i < 16; ++i) {
        int k = 0;
        while (k < INUM) {
            if (i == p[k]) {
                break;
            }
            ++k;
        }
        if (k == INUM) {
            printf("test_pseudo_distrib: FAILED. no value %u was found", i);
            return false;
        }
    }
    free(p);
    return true;
}
int main () {

    if (!test_unique(20)) {
        return EXIT_FAILURE;
    }
    if (!test_pseudo_distrib(100)) {
        return EXIT_FAILURE;
    }
    return EXIT_SUCCESS;
}
