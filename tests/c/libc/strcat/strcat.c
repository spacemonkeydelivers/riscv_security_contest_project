#include <stdlib.h>
#include <string.h>
#include <stdio.h>

int main () {
    char str[50] = "Hello ";
    char str2[50] = "World!";
    strcat(str, str2);
    char* ptr_dst = strcat(str, " Goodbye World!");
    if (str[13] != 'G') {
        printf("unexpected symbol at position 14\n");
        return EXIT_FAILURE;
    }
    if (ptr_dst != str) {
        printf("return value of *strcat* does not match the expected one %p != %p\n",
               (void*)ptr_dst, (void*)str);
        return EXIT_FAILURE;
    }
    printf("%s\n", str);
    return EXIT_SUCCESS;
}
/*
UART_CHECK:ENABLED
Hello World! Goodbye World!

*/
