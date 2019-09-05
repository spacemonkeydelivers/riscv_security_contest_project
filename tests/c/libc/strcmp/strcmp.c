#include <stdlib.h>
#include <string.h>
#include <stdio.h>

int main () {
    char l0 [] = "";
    char r0 [] = "";
    if (strcmp(l0, r0) != 0) {
        printf("error: l0 is expected to be equal to r0\n");
        return EXIT_FAILURE;
    }

    char l1 [] = "abc";
    char r1 [] = "abc";
    if (strcmp(l1, r1) != 0) {
        printf("error: l1 is expected to be equal to r1\n");
        return EXIT_FAILURE;
    }

    char l2 [] = "adc";
    char r2 [] = "abc";
    if (strcmp(l2, r2) != 1) {
        printf("error: l2 is expected to be greater than r2\n");
        return EXIT_FAILURE;
    }

    char l3 [] = "aac";
    char r3 [] = "abc";
    if (strcmp(l3, r3) != -1) {
        printf("error: l3 is expected to be less than r2\n");
        return EXIT_FAILURE;
    }

    char l4 [] = "adcD";
    char r4 [] = "abc";
    if (strcmp(l4, r4) != 1) {
        printf("error: l4 is expected to be greater than r4\n");
        return EXIT_FAILURE;
    }

    char l5 [] = "adc";
    char r5 [] = "abcD";
    if (strcmp(l5, r5) != 1) {
        printf("error: l5 is expected to be less than r5\n");
        return EXIT_FAILURE;
    }

    return EXIT_SUCCESS;
}
