#include <stdlib.h>

int __libc_start_main(int (*main)(void)) __attribute__ ((noreturn));

int __libc_start_main(int (*main)(void))
{
    int result;

    result = main();

    exit(result);
}

