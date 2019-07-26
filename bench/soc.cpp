#include <stdlib.h>
#include "Vsoc.h"
#include "verilated.h"
#include <verilated_vcd_c.h>

#include <string>
#include <cassert>

#include <stdio.h>

#include "Vsoc_wb_ram__pi1.h"
#include "Vsoc_wb_ram_generic__pi2.h"
#include "Vsoc_soc.h"

class RV_SOC
{
public:
    static const unsigned wordSize = 4;

    void tick(unsigned num = 1);
    RV_SOC(const char* trace = nullptr);
    ~RV_SOC();

    void dumpRam(unsigned start = 0, unsigned size = wordSize);
    void reset();
private:
    Vsoc*          m_soc     {nullptr};
    uint64_t       m_tickCnt {0};
    VerilatedVcdC* m_trace   {nullptr};
};

RV_SOC::RV_SOC(const char* trace)
{
    m_soc = new Vsoc;
    assert(!m_trace);
    if (trace)
    {
        Verilated::traceEverOn(true);
        m_trace = new VerilatedVcdC;
        m_soc->trace(m_trace, 99);
        m_trace->open(trace);
    }
}

RV_SOC::~RV_SOC()
{
    if (m_trace)
    {
        m_trace->close();
        m_trace = nullptr;
    }
    assert(m_soc);
    delete m_soc;
}

void RV_SOC::tick(unsigned num)
{
    assert(m_soc);
    for (unsigned i = 0; i < num; i++)
    {
        m_tickCnt++;

        m_soc->clk_i = 0;
        m_soc->eval();

        if (m_trace)
            m_trace->dump(m_tickCnt - 1);

        m_tickCnt++;
        m_soc->clk_i = 1;
        m_soc->eval();

        if (m_trace)
            m_trace->dump(m_tickCnt);

        m_soc->clk_i = 0;
        m_soc->eval();

        if (m_trace)
        {
            m_trace->dump(m_tickCnt + 1);
            m_trace->flush();
        }
    }
}

void RV_SOC::dumpRam(unsigned start, unsigned size)
{
    unsigned ramSize = sizeof(m_soc->soc->ram0->ram0->mem);
    assert(start < ramSize / wordSize);
    assert(start + size < ramSize / wordSize);
    for (unsigned i = start; i < start + size; i++)
    {
        printf("0x%08x : 0x%04x\n", i, m_soc->soc->ram0->ram0->mem[i]);
    }
}

void RV_SOC::reset()
{
    m_soc->rst_i = 1;
    tick();
    m_soc->rst_i = 0;
    tick();
}

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

    return 0;
}
