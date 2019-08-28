#include <stdlib.h>
#include <stdio.h>

int main () {
    int bla[4];
    memset(bla, 0, sizeof(bla));
    for (int i = 0; i < sizeof(bla)/sizeof(bla[0]); ++i) {
        if (bla[0] != 0) {
            printf("incorrect value dedected at %p, (zero memset)\n", (void*)bla);
            return EXIT_FAILURE;
        }
    }
    memset(bla, 1, sizeof(bla));
    for (int i = 0; i < sizeof(bla)/sizeof(bla[0]); ++i) {
        if (bla[0] != 0x01010101) {
            printf("incorrect value dedected at %p, (ones pattern)\n", (void*)bla);
            return EXIT_FAILURE;
        }
    }
    memset(bla, 0xff, sizeof(bla));
    for (int i = 0; i < sizeof(bla)/sizeof(bla[0]); ++i) {
        if (bla[0] != (int)0xffffffff) {
            printf("incorrect value dedected at %p, (ff pattern)\n", (void*)bla);
            return EXIT_FAILURE;
        }
    }
    memset(bla, 0xffaa, sizeof(bla));
    for (int i = 0; i < sizeof(bla)/sizeof(bla[0]); ++i) {
        if (bla[0] != (int)0xaaaaaaaa) {
            printf("incorrect value dedected at %p, (large v pattern)\n", (void*)bla);
            return EXIT_FAILURE;
        }
    }
    void* mst_result = memset(bla, 0x0a, sizeof(bla));
    if (mst_result != bla) {
        printf("the value returned by memset is not correct\n");
        return EXIT_FAILURE;
    }
    return EXIT_SUCCESS;
}
