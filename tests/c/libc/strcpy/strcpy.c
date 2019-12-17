#include <stdlib.h>
#include <string.h>
#include <stdio.h>

int main () {
    char buffer[10];
    memset(buffer, 0xff, sizeof(buffer));
    char* result = strcpy(buffer, "123456");
    if (result != buffer) {
        printf("ERROR: *strcpy* is expected to return destination\n");
        return EXIT_FAILURE;
    }
    char etalon_values[7];
    etalon_values[0] = '1';
    etalon_values[1] = '2';
    etalon_values[2] = '3';
    etalon_values[3] = '4';
    etalon_values[4] = '5';
    etalon_values[5] = '6';
    etalon_values[6] = 0;
    if (memcmp(etalon_values, buffer, sizeof(etalon_values)) != 0) {
        printf("ERROR: it seems that strcpy does not work correctly\n");
        return EXIT_FAILURE;
    }

    memset(buffer, 0, sizeof(buffer));
    result = strcpy(buffer, "123456");
    if (result != buffer) {
        printf("ERROR: *strcpy* is expected to return destination\n");
        return EXIT_FAILURE;
    }
    if (memcmp(etalon_values, buffer, sizeof(etalon_values)) != 0) {
        printf("ERROR: it seems that strcpy does not work correctly\n");
        return EXIT_FAILURE;
    }
    return EXIT_SUCCESS;
}
