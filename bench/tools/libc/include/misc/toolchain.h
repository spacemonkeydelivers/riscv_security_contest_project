#ifndef LIBC_MISC_INCLUDE_TOOLCHAIN_H_XF196MRW
#define LIBC_MISC_INCLUDE_TOOLCHAIN_H_XF196MRW

#ifndef __printf_like
#define __printf_like(f, a)   __attribute__((format (printf, f, a)))
#endif

#endif /* end of include guard: LIBC_MISC_INCLUDE_TOOLCHAIN_H_XF196MRW */
