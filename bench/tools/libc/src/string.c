#include <string.h>

#include <stdlib.h>
#include <stdio.h>

size_t strlen(const char *str) {
    if (str == 0) { // undefined behavior
        return 0;
    }
    size_t result = 0;
    while (*str) {
        ++str;
        ++result;
    }
    return result;
}

char *strcpy(char *restrict dest, const char *restrict src) {
    char* restrict ptr_d = dest;
    while (*ptr_d) {
        *ptr_d++ = *src;
        ++src;
    }
    *ptr_d = 0;
    return dest;
}
char *strcat(char *restrict dest, const char *restrict src) {
    char* restrict ptr_d = dest;
    while (*ptr_d) {
        ++ptr_d;
    }
    while (*src) {
        *ptr_d++ = *src;
        ++src;
    }
    *ptr_d = *src;
    return dest;
}
char *strncat(char *restrict dest, const char *restrict src, size_t count) {
    (void)dest;(void)src;(void)count;
    printf("LIBC: <PANIC> strncat not implemented\n");
    exit(42);
}
char *strncpy(char *restrict dest, const char *restrict src, size_t count) {
    (void)dest;(void)src;(void)count;
    printf("LIBC: <PANIC> strncpy not implemented\n");
    exit(42);
}


void* memcpy(void *restrict dest, const void *restrict src, size_t count) {
    unsigned char* restrict d_ptr = dest;
    const unsigned char* restrict s_ptr = src;
    for (size_t i = 0; i < count; ++i)
    {
        *d_ptr++ = *s_ptr++;
    }
    return dest;
}

void *memset(void *dest, int ch, size_t count) {
    unsigned char* d_ptr = dest;
    unsigned char filler = (unsigned char)ch;
    for (size_t i = 0; i < count; ++i)
    {
        *d_ptr++ = filler;
    }
    return dest;
}
int memcmp(const void* lhs, const void* rhs, size_t count) {
    const unsigned char* l = lhs;
    const unsigned char* r = rhs;
    for (size_t i = 0; i < count; ++i) {
        int diff = l[i] - r[i];
        if (diff != 0 ) {
            return (diff > 0) ? 1 : -1;
        }
    }
    return 0;
}

