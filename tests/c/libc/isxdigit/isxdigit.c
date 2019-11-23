#include <stdlib.h>
#include <ctype.h>

int main() {
    int num_hex_digits = 5 * 2;
    int counter = 0;
    for (int i = 0; i < 256; i++) {
        if (isxdigit(i))
            counter++;
    }
    if (counter == num_hex_digits)
        return EXIT_SUCCESS;
    else
        return EXIT_FAILURE;
}
