#ifndef __INCLUDE_GUARD_RISCV_STRING__
#define __INCLUDE_GUARD_RISCV_STRING__

#include <stdint.h>

size_t strlen(const char *str);

int strcmp(const char *lhs, const char *rhs);
char *strcpy(char *restrict dest, const char *restrict src);
char *strcat(char *restrict dest, const char *restrict src);
char *strncat(char *restrict dest, const char *restrict src, size_t count);
char *strncpy(char *restrict dest, const char *restrict src, size_t count);

void *memcpy(void *restrict dest, const void *restrict src, size_t count);
void *memset(void *dest, int ch, size_t count);
int   memcmp(const void* lhs, const void* rhs, size_t count);


#endif /* end of include guard: __INCLUDE_GUARD_RISCV_STRING__ */

