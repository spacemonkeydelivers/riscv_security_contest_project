#include <time.h>
#include <stdint.h>

extern uint64_t __mtime();

time_t time(__attribute__((unused)) time_t *tloc)
{
    return __mtime();
}

