#ifndef RND_H_ZYQ2KI1O
#define RND_H_ZYQ2KI1O

static inline unsigned soc_hwrand(void) {
    unsigned result = 0;
    __asm__ __volatile__(
            "csrr %[result], rnd\n\t"
            : [result]"=r"(result)
            : /* No Input */
            : );
    return result;
}

#endif /* end of include guard: RND_H_ZYQ2KI1O */
