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

    rv_soc.dumpRam(0, 20);
    rv_soc.doMemOp(0x10, RV_SOC::MemOpcode::READB);
    rv_soc.doMemOp(0x11, RV_SOC::MemOpcode::WRITEB);
    rv_soc.dumpRam(0, 20);

    printf("\n");
    rv_soc.doMemOp(0x0, RV_SOC::MemOpcode::WRITEB, 0x11335577);
    rv_soc.doMemOp(0x4, RV_SOC::MemOpcode::WRITEH, 0x22446688);
    rv_soc.doMemOp(0x8, RV_SOC::MemOpcode::WRITEW, 0xAABBAABB);
    rv_soc.doMemOp(0xc, RV_SOC::MemOpcode::WRITEB, 0x065560);
    rv_soc.dumpRam(0, 20);

    return 0;
}

