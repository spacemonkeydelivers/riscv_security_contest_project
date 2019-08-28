#include <stdbool.h>
#include <unistd.h>
#include <string.h>
#include <stdio.h>

#include "init_ctx.h"
#include "security.h"
#include "os.h"

#define alignto(p, bits)      (((p) >> bits) << bits)
#define aligntonext(p, bits)  alignto(((p) + (1 << bits) - 1), bits)

#define MAGIC 0xff1133aa

typedef struct alloc_header {
    unsigned alloc_size;
    unsigned next_ptr;
    unsigned is_free;
    unsigned info;
} alloc_header_t;

struct memory_subsystem {
    unsigned arena_start;
    unsigned arena_end;
    alloc_header_t* head;
    alloc_header_t* tail;
} mem_info  __attribute__((section(".__system.secure"), aligned (16)));


__attribute__((section(".__system.init")))
bool malloc_init(const struct init_ctx* ctx)
{
    if (ctx->memtag_en) {
        printf("LIBC: MEMORY TAGGING is enabled\n");
    }
    else {
        printf("LIBC: MEMORY TAGGING is disabled\n");
    }
    printf("LIBC: heap @[%p, %p]\n", (void*)ctx->heap_start, (void*)ctx->heap_end);
    // protect mem info
    struct memory_subsystem* s_info_ptr = (struct memory_subsystem*)
        _ossec_protect_ptr(&mem_info, sizeof(mem_info));

    memset(s_info_ptr, 0, sizeof(mem_info));
    s_info_ptr->arena_start = ctx->heap_start;
    s_info_ptr->arena_end   = ctx->heap_end;

    alloc_header_t* ptr = (alloc_header_t*)ctx->heap_start;

    ptr = (alloc_header_t*)_ossec_protect_ptr(ptr, sizeof(alloc_header_t));
    ptr->alloc_size = 0;
    ptr->next_ptr = 0;
    ptr->is_free = 0;
    ptr->info = MAGIC;

    s_info_ptr->head = ptr;
    s_info_ptr->tail = ptr;

    return true;
}
alloc_header_t* find_free_block(size_t size) {
    struct memory_subsystem* s_info_ptr =
        SEC_PTR(struct memory_subsystem, &mem_info);
    // we just use the fastest strategy of search...
    alloc_header_t* header = s_info_ptr->tail;
    if (header->is_free && (header->alloc_size >= size)) {
        return header;
    }
    return 0;
}
void* malloc(size_t size) {
    if (size == 0) {
        return 0; // implementation defined behavior
    }
    // Issue: at the current moment our library does not support any kind of
    // atomics/locks. And thus this malloc implementation has an issue
    // with context switch routines. For the sake simplicity we do not allow
    // malloc to modify global state if interrupts are DISABLED, that is
    // if we serve interrupts. The expectation is that such situations can
    // happen iff malloc is called from a signal
    if (_os_is_serving_isr()) {
        printf("LIBC: <WARNING> malloc should not be called from a signal!\n");
        return 0; // do not allow allocations during ISR
    }
    size = aligntonext(size, 4);
    alloc_header_t* free_header = find_free_block(size);
    if (free_header) {
        free_header->is_free = false;
        return (void*)_ossec_get_secure_ptr(free_header + 1);
    }
    struct memory_subsystem* s_info_ptr =
        SEC_PTR(struct memory_subsystem, &mem_info);

    unsigned raw_ptr = _ossec_get_essence(s_info_ptr->tail);
    unsigned next_location = raw_ptr
                    + s_info_ptr->tail->alloc_size + sizeof(alloc_header_t);

    unsigned sz_allocation = next_location + size + sizeof(alloc_header_t);
    if (sz_allocation > s_info_ptr->arena_end) {
        printf("LIBC: WARNING: OOM is detected\n");
        return 0; // OOM
    }
    free_header = (alloc_header_t*)
            _ossec_protect_ptr((void*)next_location, sizeof(alloc_header_t));
    free_header->alloc_size = size;
    free_header->is_free = false;
    free_header->next_ptr = 0;
    free_header->info = MAGIC;
    s_info_ptr->tail->next_ptr = (unsigned)free_header;
    s_info_ptr->tail = free_header;

    return (void*)_ossec_protect_ptr(
            (void*)(next_location + sizeof(alloc_header_t)), size);
}
void free(void* ptr) {
    if (ptr == 0) {
        return;
    }
    // And thus you are free!
    (void)ptr;
}
//__attribute__((section(".__system.os")))

