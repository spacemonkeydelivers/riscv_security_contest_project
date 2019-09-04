#include <stdlib.h>

int __libc_start_main(int (*main)(int, char**), int argc, char* argv[]) \
        __attribute__ ((noreturn));

int __libc_start_main(int (*main)(int, char**), int argc, char* argv[]) {
    int result;

    result = main(argc, argv);

    exit(result);
}

