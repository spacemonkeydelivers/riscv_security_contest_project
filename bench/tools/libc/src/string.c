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
/*
strncat
Appends at most count characters from the character array pointed to by src,
stopping if the null character is found, to the end of the null-terminated byte
string pointed to by dest.

The character src[0] replaces the null terminator at the end of dest. The
terminating null character is always appended in the end (so the maximum number
of bytes the function may write is count+1).

The behavior is undefined if the destination array does not have enough space for
the contents of both dest and the first count characters of src, plus the
terminating null character. The behavior is undefined if the source and
destination objects overlap. The behavior is undefined if either dest is not a
pointer to a null-terminated byte string or src is not a pointer to a character
array
*/
char *strncat(char *restrict dest, const char *restrict src, size_t count) {
    char* restrict d_ptr = dest;
    while (*d_ptr) {
        ++d_ptr;
    }
    while (count > 0) {
        *d_ptr++ = *src;
        if (*src == 0) {
            return dest;
        }
        ++src;
        --count;
    }
    *d_ptr = 0;
    return dest;
}
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
char *strncpy(char *restrict dest, const char *restrict src, size_t count) {

    char* restrict d_ptr = dest;
    while (count > 0) {
        --count;
        *d_ptr++ = *src;
        if (*src == 0) {
            break;
        }
        ++src;
    }
    while (count > 0) {
        *d_ptr++ = 0;
        --count;
    }
    return dest;
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
int strcmp(const char *lhs, const char *rhs) {
    const unsigned char* l = (const unsigned char*)lhs;
    const unsigned char* r = (const unsigned char*)rhs;
    int offset = 0;
    int diff = 0;
    while (l[offset] && r[offset]) {
        diff = l[offset] - r[offset];
        if (diff != 0) {
            return (diff > 0) ? 1 : -1;
        }
        ++offset;
    }
    diff = l[offset] - r[offset];
    if (diff == 0)
        return 0;
    return (diff > 0) ? 1 : -1;
}

void *memmove(void *dest, const void *src, size_t n) {
    const char *csrc = (char *)src; 
    char *cdst       = (char *)dest;
    char *temp       = (char *)malloc(n);
    for (size_t i = 0; i < n; ++i) {
        temp[i] = csrc[i];
    }

    for (size_t i = 0; i < n; ++i) {
        cdst[i] = temp[i];
    }

    free(temp);
    return dest;
}

char *strchr(const char *s, int c) {
    char* cur = (char*)s;
    while (*cur) {
        if (*cur == c) {
            return cur;
        } else {
            cur++;
        }
    }
    return NULL;
}
