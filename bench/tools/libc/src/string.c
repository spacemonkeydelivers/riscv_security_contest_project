#include <string.h>

#include <stdlib.h>
#include <stdio.h>

size_t strlen(const char *str) {
    (void)str;
    printf("LIBC: <PANIC> strlen not implemented\n");
    exit(42);
}

char *strcpy(char *restrict dest, const char *restrict src) {
    (void)dest;(void)src;
    printf("LIBC: <PANIC> strcpy not implemented\n");
    exit(42);
}
char *strcat(char *restrict dest, const char *restrict src) {
    (void)dest;(void)src;
    printf("LIBC: <PANIC> strcpy not implemented\n");
    printf("LIBC: <PANIC strcat not implemented>\n");
    exit(42);
}
char *strncat(char *restrict dest, const char *restrict src, size_t count) {
    (void)dest;(void)src;(void)count;
    printf("LIBC: <PANIC> strcpy not implemented\n");
    printf("LIBC: <PANIC> strncat not implemented\n");
    exit(42);
}
char *strncpy(char *restrict dest, const char *restrict src, size_t count) {
    (void)dest;(void)src;(void)count;
    printf("LIBC: <PANIC> strncpy not implemented\n");
    exit(42);
}


void* memcpy(void *restrict dest, const void *restrict src, size_t count)
{
    unsigned char* restrict d_ptr = dest;
    const unsigned char* restrict s_ptr = src;
    for (size_t i = 0; i < count; ++i)
    {
        *d_ptr++ = *s_ptr++;
    }
    return dest;
}

void *memset( void *dest, int ch, size_t count )
{
    unsigned char* d_ptr = dest;
    for (size_t i = 0; i < count; ++i)
    {
        *d_ptr++ = (unsigned char)ch;
    }
    return dest;
}

