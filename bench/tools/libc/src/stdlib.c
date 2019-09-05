#include <stdlib.h>
#include <unistd.h>

void exit(int status) {
    // TODO: call "at_exit" functions
    _exit(status);
}

// strtoul is implemented in a libc/src/strtoul
