#include <stdlib.h>
#include <stdbool.h>
#include <stdio.h>

bool case1 () {
    int r = strtoul(" 123456", 0, 10);
    if (r != 123456) {
        printf("case1: interpretation error (got %d)\n", r);
        return false;
    }
    return true;
}

bool case2 () {
    int r = strtoul(" 123456", 0, 16);
    if (r != 0x123456) {
        printf("case2: interpretation error (got %d)\n", r);
        return false;
    }
    return true;
}

bool case3 () {
    int r = strtoul("0x123a", 0, 16);
    if (r != 0x123a) {
        printf("case3: interpretation error (got %d)\n", r);
        return false;
    }
    return true;
}

bool case4 () {
    int r = strtoul("0x3fab", 0, 0);
    if (r != 0x3fab) {
        printf("case4: interpretation error (got %d)\n", r);
        return false;
    }
    return true;
}

int main () {
    if (!case1()) {
        return EXIT_FAILURE;
    }
    if (!case2()) {
        return EXIT_FAILURE;
    }
    if (!case3()) {
        return EXIT_FAILURE;
    }
    if (!case4()) {
        return EXIT_FAILURE;
    }
    return EXIT_SUCCESS;
}
