#include <stdlib.h>
#include <stdbool.h>
#include <stdio.h>

/*
strncpy
Copies at most count characters of the byte string pointed to by src (including
the terminating null character) to character array pointed to by dest.

If count is reached before the entire string src was copied, the resulting
character array is not null-terminated.

If, after copying the terminating null character from src, count is not
reached, additional null characters are written to dest until the total of
count characters have been written.
 */
bool case1 () {
    char buff1[10];
    memset(buff1, 0xff, sizeof(buff1));
    char* sr1 = strncpy(buff1, "123456789", 9);
    if (memcmp(buff1, "123456789", 9) != 0) {
        printf("case1: *strncpy* could not copy the data (data is corrupted)\n");
        return false;
    }
    if (sr1 != buff1) {
        printf("case1: the return value does not match the expected one\n");
        return false;
    }
    if (buff1[9] != 0xff) {
        printf("case1: the terminating 0 shoud not be copied if count does not allow\n");
        return false;
    }
    return true;
}
bool case2 () {
    char buff1[10];
    memset(buff1, 0xaa, sizeof(buff1));
    char* sr2 = strncpy(buff1, "", 2);
    if (sr2 != buff1) {
        printf("case2: the return value does not match the expected one\n");
        return false;
    }
    if (buff1[0] != 0) {
        printf("case2: terminating was not copied\n");
        return false;
    }
    if (buff1[1] != 0) {
        printf("case2: insufficient number of bytes were copied\n");
        return false;
    }
    if (buff1[2] != 0xaa) {
        printf("case2: too much data was copied\n");
        return false;
    }
    return true;
}
bool case3 () {
    char buff1[10];
    memset(buff1, 0xbb, sizeof(buff1));
    char* sr3 = strncpy(buff1, "12", 0);
    if (buff1[0] != 0xbb) {
        printf("case3: no data should be copied if count is 0\n");
        return false;
    }
    if (sr3 != buff1) {
        printf("case3: the return value does not match the expected one\n");
        return false;
    }
    return true;
}
bool case4 () {
    char buff1[10];
    memset(buff1, 0xba, sizeof(buff1));
    char* sr4 = strncpy(buff1, "12", 3);
    if (buff1[3] != 0) {
        printf("case4: no terminating character detected at pos #3\n");
        return false;
    }
    if ((buff1[0] != '1') || (buff1[1] != '2')) {
        printf("case4: desination is corrupted\n");
        return false;
    }
    if (sr4 != buff1) {
        printf("case4: the return value does not match the expected one\n");
        return false;
    }
    return true;
}
bool case5 () {
    char buff1[10];
    memset(buff1, 0xba, sizeof(buff1));
    char* sr5 = strncpy(buff1, "12", 2);
    if (buff1[3] == 0) {
        printf("case5: terminating character detected at pos #3\n");
        return false;
    }
    if (sr5 != buff1) {
        printf("case5: the return value does not match the expected one\n");
        return false;
    }
    if ((buff1[0] != '1') || (buff1[1] != '2')) {
        printf("case5: desination is corrupted\n");
        return false;
    }
    return true;
}
bool case6 () {
    char buff1[10];
    memset(buff1, 0xba, sizeof(buff1));
    char* sr6 = strncpy(buff1, "12", 1);
    if (sr6 != buff1) {
        printf("case6: the return value does not match the expected one\n");
        return false;
    }
    if (buff1[0] != '1') {
        printf("case6: desination is corrupted\n");
        return false;
    }
    if (buff1[1] == 0) {
        printf("case6: terminating character detected at pos #1\n");
        return false;
    }
    return true;
}
int main () {
    // case_1:
    if (!case1()) { return EXIT_FAILURE; }
    // case_2
    if (!case2()) { return EXIT_FAILURE; }
    // case_3
    if (!case3()) { return EXIT_FAILURE; }
    // case_4
    if (!case4()) { return EXIT_FAILURE; }
    // case_5
    if (!case5()) { return EXIT_FAILURE; }
    // case_6
    if (!case6()) { return EXIT_FAILURE; }
    return EXIT_SUCCESS;
}
