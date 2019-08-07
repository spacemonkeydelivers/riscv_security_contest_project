#ifndef __INCLUDE_GUARD_RISCV_STDINT__
#define __INCLUDE_GUARD_RISCV_STDINT__

// TODO: size_t does not belong here.
typedef unsigned size_t;
typedef signed   intptr_t;
typedef unsigned uintptr_t;


// TODO: this header is buggy as the values are taken from x86
typedef signed char        int8_t;
typedef signed short       int16_t;
typedef signed int         int32_t;
typedef signed long long   int64_t;
typedef signed char        int_least8_t;
typedef signed short       int_least16_t;
typedef signed int         int_least32_t;
typedef signed long long   int_least64_t;
typedef signed char        int_fast8_t;
typedef signed short       int_fast16_t;
typedef signed int         int_fast32_t;
typedef signed long long   int_fast64_t;
typedef signed long long   intmax_t;

typedef unsigned char      uint8_t;
typedef unsigned short     uint16_t;
typedef unsigned int       uint32_t;
typedef unsigned long long uint64_t;
typedef unsigned char      uint_least8_t;
typedef unsigned short     uint_least16_t;
typedef unsigned int       uint_least32_t;
typedef unsigned long long uint_least64_t;
typedef unsigned char      uint_fast8_t;
typedef unsigned short     uint_fast16_t;
typedef unsigned int       uint_fast32_t;
typedef unsigned long long uint_fast64_t;
typedef unsigned long long uintmax_t;

#define INT8_MIN        0x80
#define INT16_MIN       0x8000
#define INT32_MIN       0x80000000
#define INT64_MIN       0x8000000000000000ll
#define INT_LEAST8_MIN  0x80
#define INT_LEAST16_MIN 0x8000
#define INT_LEAST32_MIN 0x80000000
#define INT_LEAST64_MIN 0x8000000000000000ll
#define INT_FAST8_MIN   0x80
#define INT_FAST16_MIN  0x8000
#define INT_FAST32_MIN  0x80000000
#define INT_FAST64_MIN  0x8000000000000000ll
#define INTPTR_MIN      0x8000000000000000ll
#define INTMAX_MIN      0x8000000000000000ll

#define INT8_MAX        0x7F
#define INT16_MAX       0x7FFF
#define INT32_MAX       0x7FFFFFFF
#define INT64_MAX       0x7FFFFFFFFFFFFFFFll
#define INT_LEAST8_MAX  0x7F
#define INT_LEAST16_MAX 0x7FFF
#define INT_LEAST32_MAX 0x7FFFFFFF
#define INT_LEAST64_MAX 0x7FFFFFFFFFFFFFFFll
#define INT_FAST8_MAX   0x7F
#define INT_FAST16_MAX  0x7FFF
#define INT_FAST32_MAX  0x7FFFFFFF
#define INT_FAST64_MAX  0x7FFFFFFFFFFFFFFFll
#define INTPTR_MAX      0x7FFFFFFFFFFFFFFFll
#define INTMAX_MAX      0x7FFFFFFFFFFFFFFFll

#define UINT8_MAX        0xFF
#define UINT16_MAX       0xFFFF
#define UINT32_MAX       0xFFFFFFFF
#define UINT64_MAX       0xFFFFFFFFFFFFFFFFull
#define UINT_LEAST8_MAX  0xFF
#define UINT_LEAST16_MAX 0xFFFF
#define UINT_LEAST32_MAX 0xFFFFFFFF
#define UINT_LEAST64_MAX 0xFFFFFFFFFFFFFFFFull
#define UINT_FAST8_MAX   0xFF
#define UINT_FAST16_MAX  0xFFFF
#define UINT_FAST32_MAX  0xFFFFFFFF
#define UINT_FAST64_MAX  0xFFFFFFFFFFFFFFFFull
#define UINTPTR_MAX      0xFFFFFFFFFFFFFFFFull
#define UINTMAX_MAX      0xFFFFFFFFFFFFFFFFull

#define INT8_C(c) c
#define INT16_C(c) c
#define INT32_C(c) c
#define INT64_C(c) c ## ll
#define INTMAX_C(c) c ## ll
#define INTPTR_C(c) c ## ll

#define UINT8_C(c) c ## u
#define UINT16_C(c) c ## u
#define UINT32_C(c) c ## u
#define UINT64_C(c) c ## ull
#define UINTMAX_C(c) c ## ull
#define UINTPTR_C(c) c ## ull

#endif /* end of include guard: __INCLUDE_GUARD_RISCV_STDINT__ */
