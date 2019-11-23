#include <stdlib.h>
#include <ctype.h>

int main() {
    char a[5] = {'1', 'a', 'A', '\n', 'Q'};
    char b[5] = {'1', 'a', 'a', '\n', 'q'};
    for (int i = 0; i < 5; i++) {
        if (b[i] != tolower(a[i]))
            return EXIT_FAILURE;
    }
    return EXIT_SUCCESS;
}
