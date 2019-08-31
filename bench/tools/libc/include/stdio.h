#ifndef __INCLUDE_GUARD_RISCV_STDIO__
#define __INCLUDE_GUARD_RISCV_STDIO__

#include <stddef.h>
#include <stdarg.h>

#include <misc/toolchain.h>

#define stdin 0
#define stdout 1
#define stderr 2

extern int __printf_like(1, 2) printf_(const char* format, ...);
int __printf_like(2, 3) sprintf_(char* buffer, const char* format, ...);
int __printf_like(3, 4) snprintf_(char* buffer, size_t count, const char* format, ...);
int __printf_like(3, 0) vsnprintf_(char* buffer, size_t count, const char* format, va_list va);
int __printf_like(1, 0) vprintf_(const char* format, va_list va);
int fprintf_ (int stream, const char * format, ...);
// use output function (instead of buffer) for streamlike interface
int fctprintf(void (*out)(char character, void* arg), void* arg, const char* format, ...);

#define printf printf_
#define sprintf sprintf_
#define snprintf  snprintf_
#define vsnprintf vsnprintf_
#define vprintf vprintf_
#define fprintf fprintf_

#endif /* end of include guard: __INCLUDE_GUARD_RISCV_STDIO__ */

