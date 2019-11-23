#include <stdlib.h>
#include <ctype.h>

int main() {
    int num_space_char = 2; // space and tab
    int counter = 0;
    for (int i = 0; i < 256; i++) {
        if (isspace(i))
            counter++;
    }
    if (counter == num_space_char)
        return EXIT_SUCCESS;
    else
        return EXIT_FAILURE;
}
