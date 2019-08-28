#include <stdlib.h>
#include <unistd.h>

void exit(int status)
{
    _exit(status);
}

#include <stdio.h>
unsigned long  strtoul(const char *restrict str, char **restrict str_end,
                       int base) {
    (void)str;(void)str_end;(void)base;
    printf("LIBC: <PANIC> strtoul is not implemented\n");
    exit(42);
    return 0;
}


