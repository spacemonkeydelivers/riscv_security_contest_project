#ifndef __INCLUDE_GUARD_RISCV_STDLIB__
#define __INCLUDE_GUARD_RISCV_STDLIB__

#include <stddef.h>

#define EXIT_SUCCESS 0
#define EXIT_FAILURE 1

void* malloc(size_t size);
void free(void*);

void exit(int status) __attribute__ ((noreturn));

unsigned long  strtoul(const char *restrict str, char **restrict str_end,
                       int base);

static inline int abs(int val) {
    return val < 0 ? -val : val;
}

static inline long int labs(long int val) {
    return val < 0l ? -val : val;
}

static inline long long int llabs(long long int val) {
    return val < 0ll ? -val : val;
}

static inline unsigned rand(void) {
    unsigned result = 0;
    __asm__ __volatile__(
            "csrr %[result], rnd\n\t"
            : [result]"=r"(result)
            : /* No Input */
            : );
    return result;
}

#endif /* end of include guard: __INCLUDE_GUARD_RISCV_STDLIB__ */

