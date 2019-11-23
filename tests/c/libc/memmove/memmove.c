#include <stdlib.h>
#include <string.h>

int main() {
    char a[4] = {'A', 'B', 'C', 'D'};
    char b[4] = {'B', 'C', 'D', 'D'};
    char* src = &a[1];
    char* dst = &a[0];
    memmove(dst, src, 3);
    for (int i = 0; i < 4; i++) {
        if (a[i] != b[i])
            return EXIT_FAILURE;
    }
    return EXIT_SUCCESS;
}
