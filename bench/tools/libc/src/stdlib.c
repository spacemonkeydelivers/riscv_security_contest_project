#include <stdlib.h>
#include <unistd.h>

void exit(int status)
{
    _exit(status);
}

// strtoul is implemented in a libc/src/strtoul

int fprintf_(int stream, const char * format, ...) {
	(void)stream; (void)format;
	return 0;
}
