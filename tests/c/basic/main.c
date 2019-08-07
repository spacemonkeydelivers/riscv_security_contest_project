#include <stdlib.h>
#include <stdio.h>


/*
    To run using OVPsim:
    iss.exe --processorvendor riscv.ovpworld.org \
            --processorname riscv \
            --variant RV32IMC \
            --program tests/c_basic/test.elf  \
            --verbose -trace
*/

int main ()
{
    printf("test function: %s", "test");
    exit(0);
    return 0;
}
