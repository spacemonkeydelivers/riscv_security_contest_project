#include <stdlib.h>
#include <string.h>
#include <stdio.h>

int main () {
    char* zero = "";
    char* two_chars = "12";
    if (strlen(zero) != 0) {
        printf("strlen: result for zero-length string is incorrect\n");
        return EXIT_FAILURE;
    }
    if (strlen(two_chars) != 2) {
        printf("strlen: result for string from 2 characters is incorrect\n");
        return EXIT_FAILURE;
    }
    return EXIT_SUCCESS;
}
