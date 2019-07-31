#include <bench/soc.h>

// verilator headers
#include <verilated.h>
#include <verilated_vcd_c.h>

int main(int argc, char **argv)
{
    Verilated::commandArgs(argc, argv);

    RV_SOC rv_soc("trace.vcd");

    rv_soc.tick(10);
    rv_soc.reset();
    rv_soc.tick(20);
    rv_soc.reset();
    rv_soc.tick(20);

    return 0;
}

