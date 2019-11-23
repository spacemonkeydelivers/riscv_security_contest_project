#include <stdlib.h>
#include <ctype.h>

int main() {
    int num_digit = 10;
    int counter = 0;
    for (int i = 0; i < 256; i++) {
        if (isdigit(i))
            counter++;
    }
    if (counter == num_digit)
        return EXIT_SUCCESS;
    else
        return EXIT_FAILURE;
}
