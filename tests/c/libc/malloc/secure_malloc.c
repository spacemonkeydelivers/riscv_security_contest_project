#include <stdlib.h>

int main () {
    unsigned char* ptr = (unsigned char*)malloc(64);
    if (ptr) {
        for (int i = 0; i < 64; ++i) {
            ptr[i] = i;
        }
        // ptr[65]; //BOOM!
        return EXIT_SUCCESS;
    }
    return EXIT_FAILURE;
}
