#include <stdlib.h>
#include <ctype.h>

int main() {
    int num_alpha_chars = 26 * 2; //26 letters in english alphabet * {lower,upper}
    int counter = 0;
    for (int i = 0; i < 256; i++) {
        if (isalpha(i))
            counter++;
    }
    if (counter == num_alpha_chars)
        return EXIT_SUCCESS;
    else
        return EXIT_FAILURE;
}
