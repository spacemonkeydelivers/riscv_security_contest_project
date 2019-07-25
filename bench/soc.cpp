#include <stdlib.h>
#include "Vsoc.h"
#include "verilated.h"

#include <stdio.h>

int main(int argc, char **argv)
{
    fprintf(stderr, "HELLO\n");

    Verilated::commandArgs(argc, argv);
    // Create an instance of our module under test
    Vsoc* soc = new Vsoc;

    soc->rst_i = 0;
    for (int i = 0; i < 100; i++)
    {
        soc->clk_i = 1;
        soc->eval();
        soc->clk_i = 0;
        soc->eval();
    }

    return 0;
}
