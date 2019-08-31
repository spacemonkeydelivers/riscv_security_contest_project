#include <stdlib.h>
#include <unistd.h>

void exit(int status)
{
    _exit(status);
}

// strtoul is implemented in a libc/src/strtoul
