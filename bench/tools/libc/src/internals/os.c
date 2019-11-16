#include <generated/esf.h>
#include <soc/traps.h>
#include <soc/timer.h>
#include <stdint.h>
#include <stdio.h>

#include "init_ctx.h"
#include "security.h"

extern unsigned _ossec_panic();
extern bool malloc_init(const struct init_ctx* ctx);
extern void exit(int status);


__attribute__((section(".__system.data")))
uint32_t __EXC_service[RISCV_EXC_TOTAL] = {};
__attribute__((section(".__system.data")))
uint32_t __INT_service[RISCV_INT_TOTAL] = {};


__attribute__((section(".__system.os")))
exc_handler_t register_exc_handler(int exc, exc_handler_t h) {
    exc_handler_t result = 0;
    if (exc < 0) {
        exc = RISCV_EXC_TOTAL;
    }
    if (exc < RISCV_EXC_TOTAL) {
        result = (exc_handler_t)__EXC_service[exc];
        // TODO.BUG: we have to be sure that we have an atomic access here
        // should we introduce some locks?
        __EXC_service[exc] = (uint32_t)h;
    }
    else {
        result = (const void*)-1;
    }
    return result;
}
__attribute__((section(".__system.os")))
int_handler_t register_int_handler(int n, int_handler_t h) {
    int_handler_t result = 0;
    if (n < 0) {
        n = RISCV_INT_TOTAL;
    }
    if (n < RISCV_INT_TOTAL) {
        result = (int_handler_t)__INT_service[n];
        // TODO.BUG: we have to be sure that we have an atomic access here
        // should we introduce some locks?
        __INT_service[n] = (uint32_t)h;
    }
    else {
        result = (const void*)-1;
    }
    return result;
}

__attribute__((section(".__system.os")))
int __exc_serve(struct s_esf_frame* frame, int exc) {
    if (exc < 0 || exc >= RISCV_EXC_TOTAL) {
        return -1;
    }
    // TODO.BUG: we have to be sure that we have an atomic access here
    // should we introduce some locks?
    exc_handler_t h = (exc_handler_t)__EXC_service[exc];
    if (h) {
        h(exc, frame);
    }
    return 0;
}

__attribute__((section(".__system.os")))
int __int_serve(struct s_esf_frame* frame, int n) {
    if (n < 0 || n >= RISCV_INT_TOTAL) {
        return -1;
    }
    // TODO.BUG: we have to be sure that we have an atomic access here
    // should we introduce some locks?
    int_handler_t h = (int_handler_t)__INT_service[n];
    if (h) {
        h(n, frame);
    }
    // Secure Monitore Panic is fatal
    if (n == RISCV_INT_SM_PANIC) {
        _ossec_panic();
    }
    return 0;
}

#define MTIME_BASE     0x40000000
#define MTIMECMP_BASE  0x40000008
#define MTIMEFREQ_BASE 0x40000010
#define MTIME_AE_BASE  0x40000018

__attribute__((section(".__system.os")))
uint64_t __mtime() {
    volatile uint32_t *r = (uint32_t *)MTIME_BASE;

    uint32_t lo = 0;
    uint32_t hi = 0;

    // guard against rollover when reading
    do {
        hi = r[1];
        lo = r[0];
    } while (r[1] != hi);

    return (((uint64_t)hi) << 32) | lo;
}

__attribute__((section(".__system.os")))
uint64_t __mtime_alw_en() {
    volatile uint32_t *r = (uint32_t *)MTIME_AE_BASE;

    uint32_t lo = 0;
    uint32_t hi = 0;

    // guard against rollover when reading
    do {
        hi = r[1];
        lo = r[0];
    } while (r[1] != hi);

    return (((uint64_t)hi) << 32) | lo;
}

__attribute__((section(".__system.os")))
static void __set_mtimecmp(uint64_t time) {
    volatile uint32_t *r = (uint32_t *)MTIMECMP_BASE;

    r[1] = 0xffffffff;
    r[0] = (uint32_t)time;
    r[1] = (uint32_t)(time >> 32);
}

__attribute__((section(".__system.os")))
static void __set_mtimefreq(uint64_t freq) {
    volatile uint32_t *r = (uint32_t *)MTIMEFREQ_BASE;

    r[1] = (uint32_t)(freq >> 32);
    r[0] = (uint32_t)freq;
}

__attribute__((section(".__system.os")))
bool alarm_soc_timer(int interval)
{
    if (interval < 0) {
        return false;
    }
    uint64_t time = __mtime();

    __set_mtimecmp(time + interval);
    __set_mtimefreq(1);

    uint32_t timer_enable = 0x80;
    uint32_t val = 0;

    // Enable interrupts
    __asm__ volatile ("csrr %[reg], mie\n\t"
                      "or %[new], %[reg], %[new]\n\t"
                      "csrw mie, %[new]\n\t"
                      :
                      : [new]"r"(timer_enable),
                        [reg]"r"(val));

    return true;
}

void alarm_soc_timer_stop() {
    uint32_t timer_disable = -1;
    timer_disable ^= 0x80;
    uint32_t val = 0;

    // Disable interrupts
    __asm__ volatile ("csrr %[reg], mie\n\t"
                      "and %[new], %[reg], %[new]\n\t"
                      "csrw mie, %[new]\n\t"
                      "csrw mip, zero\n\t"
                      :
                      : [new]"r"(timer_disable),
                        [reg]"r"(val));
    __set_mtimecmp(0);
}

__attribute__((section(".__system.os")))
void _putchar(char character) {
    (void)character;
    if (character == '\0')
        return;
    volatile char* dst = (volatile char*)0x80000004;
    *dst = character;
}
__attribute__((section(".__system.os")))
int _os_is_serving_isr () {
    int result = 0;
    __asm__ (
            "csrr %[result], mstatus\n\t"
            "li t0, 8\n\t"
            "and %[result], %[result], t0\n\t"
            : [result]"=r"(result)
            :
            : "t0");
    return result == 0;
}

__attribute__((section(".__system.init")))
void __soc_init(const struct init_ctx* ctx)
{
    if (!_ossec_init(ctx)) {
        printf("LIBC: <PANIC> could not initialize security subsystem");
        exit(253);
    }
    if (!malloc_init(ctx)) {
        printf("LIBC: <PANIC> could not initialize memory subsystem");
        exit(254);
    }
}

