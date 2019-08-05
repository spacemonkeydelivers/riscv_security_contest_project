#include <string.h>

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

