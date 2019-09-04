#include "security.h"

#include <stdlib.h>
#include <stdio.h>
#include <string.h>

volatile struct secure_context_t {
    volatile int32_t tag_gen;
    volatile int32_t sec_tag;
    int32_t pad0;
    int32_t pad1;
} sec_cntx __attribute__((section(".__system.secure_data"), aligned (16)));

__attribute__((section(".__system.init")))
unsigned _ossec_init       (const struct init_ctx* ctx) {
    (void)ctx;
    _Static_assert (sizeof(sec_cntx) == 16, "secure context must be 16 bytes");
    memset((void*)&sec_cntx, 0, sizeof(sec_cntx));

    int32_t sec_tag = 0;
    do {
        sec_tag = rand() & 0xf;
    }while(sec_tag == 0);
    sec_cntx.sec_tag = sec_tag;

    do {
       sec_cntx.tag_gen = rand() & 0xf;
    } while (sec_cntx.tag_gen == 0 || sec_cntx.tag_gen == sec_tag);

    int en_value = 1;
    unsigned ptr = (unsigned)&sec_cntx;
    __asm__ __volatile__(
            "csrw tags, %[en_value]\n\t"
            "li t0, (~(0xf << 26))\n\t"
            "and t1, %[ptr], t0\n\t"
            "or t0, %[sec_tag], x0\n\t"
            "st t0, 0(t1)"
            : /* No outputs. */
            : [en_value]"r" (en_value),
              [ptr]"r" (ptr),
              [sec_tag]"r" (sec_tag)
            : "t0", "t1",  "memory");
    return 1;
}

__attribute__((section(".__system.os")))
static unsigned _ossec_get_protected_ptr(unsigned ptr) {
    unsigned result = 0;
    __asm__ __volatile__(
            "li t0, (~(0xf << 26))\n\t"
            "and t0, %[ptr], t0\n\t"
            "lt t1, 0(t0)\n\t" //load tag
            "slli t1, t1, 26\n\t"
            "or %[result], t0, t1"
            : [result]"=r"(result)
            : [ptr]"r" (ptr)
            : "t0", "t1",  "memory");
    return result;
}

typedef volatile struct secure_context_t* volatile ctx_ptr_t;
__attribute__((section(".__system.os")))
unsigned _ossec_generate_tag () {
    ctx_ptr_t ptr = (ctx_ptr_t)_ossec_get_protected_ptr((unsigned)&sec_cntx);
    int32_t new_tag = ptr->tag_gen;

    // we do not use "0" and secure tags
    do {
        ptr->tag_gen = (ptr->tag_gen + 1) & 0xf; // TODO: rework to use rand() instead of '+1' in future
    } while(ptr->tag_gen == 0 || ptr->tag_gen == ptr->sec_tag);

    return new_tag;
}

__attribute__((section(".__system.os")))
unsigned _ossec_alignment_assert(unsigned ptr) {
    printf("PANIC: ALIGNMENT VIOLATION @[0x%x]\n", ptr);
    exit(43);
    return 0;
}

#define GRANULE_SIZE 16
__attribute__((section(".__system.os")))
unsigned _ossec_protect_ptr(volatile void* ptr, unsigned size) {
    unsigned tag = _ossec_generate_tag();
    unsigned raw_ptr = (unsigned)ptr;
    if (raw_ptr % 16) {
        _ossec_alignment_assert(raw_ptr);
    }
    unsigned untagged_ptr = (raw_ptr & (~(0xf << 26)));

    unsigned granules_to_tag = size / GRANULE_SIZE + ((size % GRANULE_SIZE) ? 1 : 0);
    unsigned address_to_tag = untagged_ptr;
    for (unsigned i = 0; i < granules_to_tag; ++i) {
        __asm__ __volatile__(
                "st %[tag], 0(%[address])"
                :
                : [tag]"r"(tag), [address]"r"(address_to_tag)
                : "t0", "memory");
        address_to_tag += 16;
    }
    unsigned result =  untagged_ptr | (tag << 26);
    return result;
}
__attribute__((section(".__system.os")))
unsigned _ossec_get_essence(volatile void* ptr) {
    return ((unsigned)ptr) & ((1 << 26) - 1);
}

__attribute__((section(".__system.os")))
unsigned _ossec_get_secure_ptr(volatile void* ptr) {
    return _ossec_get_protected_ptr((unsigned)ptr);
}

__attribute__((section(".__system.os")))
unsigned _ossec_panic() {
    printf("LIBC: <PANIC> SECURITY VIOLATION DETECTED!\n");
    exit(42);
    return 0;
}

