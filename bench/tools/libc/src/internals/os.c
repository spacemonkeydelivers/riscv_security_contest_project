#include <generated/esf.h>
#include <soc/traps.h>
#include <soc/timer.h>
#include <stdint.h>
#include <stdio.h>

#include "init_ctx.h"
#include "security.h"


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
    return 0;
}
__attribute__((section(".__system.os")))
bool alarm_soc_timer(int interval)
{
    if (interval < 0) {
        return false;
    }
    int timer_address = 0x40000000;
    __asm__ volatile ("sw %[threshold], 0(%[timer_addr])"
                      :
                      : [timer_addr]"r" (timer_address),
                        [threshold]"r"(interval)
                      : "memory");
    return true;

}

__attribute__((section(".__system.os")))
void _putchar(char character) {
    (void)character;
    if (character == '\0')
        return;
    volatile char* dst = (volatile char*)0x80000003;
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

extern bool malloc_init(const struct init_ctx* ctx);
extern void exit(int status);

__attribute__((section(".__system.init")))
void __soc_init(const struct init_ctx* ctx)
{
    if (!_ossec_init(ctx)) {
        printf("PANIC: could not initialize security subsystem");
        exit(253);
    }
    if (!malloc_init(ctx)) {
        printf("PANIC: could not initialize memory subsystem");
        exit(254);
    }
}

