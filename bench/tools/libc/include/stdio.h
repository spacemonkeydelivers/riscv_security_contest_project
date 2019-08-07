#ifndef __INCLUDE_GUARD_RISCV_STDIO__
#define __INCLUDE_GUARD_RISCV_STDIO__

#include <stddef.h>
#include <stdarg.h>

extern int printf_(const char* format, ...);
int sprintf_(char* buffer, const char* format, ...);
int snprintf_(char* buffer, size_t count, const char* format, ...);
int vsnprintf_(char* buffer, size_t count, const char* format, va_list va);
int vprintf_(const char* format, va_list va);

// use output function (instead of buffer) for streamlike interface
int fctprintf(void (*out)(char character, void* arg), void* arg, const char* format, ...);

#define printf printf_
#define sprintf sprintf_
#define snprintf  snprintf_
#define vsnprintf vsnprintf_
#define vprintf vprintf_

#endif /* end of include guard: __INCLUDE_GUARD_RISCV_STDIO__ */

