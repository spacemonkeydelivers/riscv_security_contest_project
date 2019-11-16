#include <Vsoc_includes.h>

#include <cassert>

#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>

#include <unistd.h>

int log_file_open (const char* log_name)
{
    int fd = open(log_name, O_DSYNC | O_CREAT | O_RDWR);
    return fd;
}

void log_file_write (int log_fd, int data)
{
    assert(data == (data & 0xFF));
    char byte = data & 0xFF;
    write(log_fd, &byte, 1);
}
