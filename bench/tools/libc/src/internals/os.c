#include <generated/esf.h>
#include <soc/traps.h>
#include <stdint.h>


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
    int_handler_t h = (int_handler_t)__INT_service[n];
    if (h) {
        h(n, frame);
    }
    return 0;
}

__attribute__((section(".__system.init")))
void __soc_init(const void* context)
{
    (void)context;
}

