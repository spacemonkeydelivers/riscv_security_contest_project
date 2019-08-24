#ifndef SECURITY_H_MY3N1HL9
#define SECURITY_H_MY3N1HL9

#include "init_ctx.h"

// returns protected pointer
unsigned _ossec_protect_ptr(volatile void* ptr, unsigned size);
// optional. we could just re-protect...
unsigned _ossec_get_secure_ptr(volatile void* ptr);
// initializes security subsystem
unsigned _ossec_init       (const struct init_ctx* ctx);

unsigned _ossec_get_essence(volatile void* ptr);


#define SEC_PTR(type, ptr) ((type*)_ossec_get_secure_ptr(ptr))
#define CSEC_PTR(type, ptr) ((const type*)_ossec_get_secure_ptr(ptr))

#endif /* end of include guard: SECURITY_H_MY3N1HL9 */
