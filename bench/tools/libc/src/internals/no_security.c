#include "security.h"

#include <stdlib.h>
#include <stdio.h>
#include <string.h>

__attribute__((section(".__system.init")))
unsigned _ossec_init       (const struct init_ctx* ctx) {
    (void)ctx;
    printf("LIBC: <WARNING> your are using NON-secure libc\n");
    return 1;
}

/*
__attribute__((section(".__system.os")))
static unsigned _ossec_get_protected_ptr(unsigned ptr) {
    (void)ptr;
    return ptr;
}
*/
__attribute__((section(".__system.os")))
unsigned _ossec_generate_tag () {
    return 0;
}
__attribute__((section(".__system.os")))
unsigned _ossec_alignment_assert(unsigned ptr) {
    (void)ptr;
    return 0;
}

__attribute__((section(".__system.os")))
unsigned _ossec_protect_ptr(volatile void* ptr, unsigned size) {
    (void)ptr;(void)size;
    return (unsigned)ptr;
}
__attribute__((section(".__system.os")))
unsigned _ossec_get_essence(volatile void* ptr) {
    return (unsigned)ptr;
}

__attribute__((section(".__system.os")))
unsigned _ossec_get_secure_ptr(volatile void* ptr) {
    return (unsigned)ptr;
}

__attribute__((section(".__system.os")))
unsigned _ossec_panic() {
    printf("LIBC: <PANIC> SECURITY VIOLATION DETECTED!\n");
    exit(42);
    return 0;
}

