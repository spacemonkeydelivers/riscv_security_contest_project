#include <stdbool.h>
#include <stdlib.h>
#include <stdio.h>

/*
Appends at most count characters from the character array pointed to by src,
stopping if the null character is found, to the end of the null-terminated byte
string pointed to by dest.

The character src[0] replaces the null terminator at the end of dest. The
terminating null character is always appended in the end (so the maximum number
of bytes the function may write is count+1).

The behavior is undefined if the destination array does not have enough space
for the contents of both dest and the first count characters of src, plus the
terminating null character. The behavior is undefined if the source and
destination objects overlap. The behavior is undefined if either dest is not a
pointer to a null-terminated byte string or src is not a pointer to a character
array
*/
bool case1 () {
    char buffer[10];
    char ref_buff[10];
    memset(buffer, 1, sizeof(buffer));
    buffer[0] = 0;
    memset(ref_buff, 1, sizeof(ref_buff));
    char* result = strncat(buffer, "", 0);
    if (buffer[0] != 0) {
        printf("case1: no terminating null after strncat\n");
        return false;
    }
    if (result != buffer) {
        printf("case1: returned value does not match the expected\n");
        return false;
    }
    if (memcmp(buffer + 1, ref_buff, sizeof(buffer) - 1) != 0) {
        printf("case1: destination is not consistent\n");
        return false;
    }
    return true;
}
bool case2 () {
    char buffer[10];
    char ref_buff[10];
    memset(buffer, 1, sizeof(buffer));
    buffer[0] = 0;
    memset(ref_buff, 1, sizeof(ref_buff));
    char* result = strncat(buffer, "", 1);
    if (buffer[0] != 0) {
        printf("case2: no terminating null after strncat\n");
        return false;
    }
    if (result != buffer) {
        printf("case2: returned value does not match the expected\n");
        return false;
    }
    if (memcmp(buffer + 1, ref_buff, sizeof(buffer) - 1) != 0) {
        printf("case2: destination is not consistent\n");
        return false;
    }
    return true;
}
bool case3 () {
    char buffer[10];
    memset(buffer, 1, sizeof(buffer));
    buffer[0] = 'H';
    buffer[1] = 'e';
    buffer[2] = 0;
    char* result = strncat(buffer, "llo", 2);
    if (result != buffer) {
        printf("case3: returned value does not match the expected\n");
        return false;
    }
    if (buffer[4] != 0) {
        printf("case3: no terminating character detected at pos #4\n");
        return false;
    }
    if (memcmp(buffer, "Hell", 4) != 0) {
        printf("case3: the data in the destination is incorrect\n");
        return false;
    }
    return true;
}
bool case4 () {
    char buffer[10];
    memset(buffer, 1, sizeof(buffer));
    buffer[0] = 'H';
    buffer[1] = 'e';
    buffer[2] = 0;
    char* result = strncat(buffer, "llo", 3);
    if (buffer[5] != 0) {
        printf("case4: no terminating character detected at pos #5\n");
        return false;
    }
    if (result != buffer) {
        printf("case4: returned value does not match the expected\n");
        return false;
    }
    if (memcmp(buffer, "Hello", 5) != 0) {
        printf("case4: the data in the destination is incorrect\n");
        return false;
    }
    return true;
}
bool case5 () {
    char buffer[10];
    memset(buffer, 1, sizeof(buffer));
    buffer[0] = 'H';
    buffer[1] = 'e';
    buffer[2] = 0;
    char* result = strncat(buffer, "llo", 100500);
    if (buffer[5] != 0) {
        printf("case5: no terminating character detected at pos #5\n");
        return false;
    }
    if (buffer[6] != 1) {
        printf("case5: data corruption at pos #6\n");
        return false;
    }
    if (result != buffer) {
        printf("case5: returned value does not match the expected\n");
        return false;
    }
    if (memcmp(buffer, "Hello", 5) != 0) {
        printf("case5: the data in the destination is incorrect\n");
        return false;
    }
    return true;
}
/*bool case6 () {*/
    /*char buffer[10];*/
    /*char ref_buff[10];*/
/*}*/
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
    // if (!case6()) { return EXIT_FAILURE; }

    return EXIT_SUCCESS;
}
