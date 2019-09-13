#include <cstdlib>
#include <string>
#include <cassert>
#include <cstdio>
#include <stdexcept>
#include <iostream>

// verilator headers
#include <verilated.h>
#include <verilated_vcd_c.h>

// rtlsim headers (generated by verilator)
#include <rtlsim/Vsoc.h>

#if D_SOC_RAM_SIZE == 131072
    #include <rtlsim/Vsoc_wb_ram__WC8000.h>
    #include <rtlsim/Vsoc_generic_ram__R8000_RB0.h>
    #include <rtlsim/Vsoc_generic_ram__R2000_RC4_RB0.h>
    // typedef Vsoc_wb_ram__WC8000 rtl_soc_t;
#endif

#if D_SOC_RAM_SIZE == 65536
    #include <rtlsim/Vsoc_wb_ram__WC4000.h>
    #include <rtlsim/Vsoc_generic_ram__R4000_RB0.h>
    #include <rtlsim/Vsoc_generic_ram__R1000_RC4_RB0.h>
    // typedef Vsoc_wb_ram__WC4000 rtl_soc_t;
#endif

#include <rtlsim/Vsoc_soc.h>
#include <rtlsim/Vsoc_wb_cpu_bus.h>
#include <rtlsim/Vsoc_registers.h>
#include <rtlsim/Vsoc_cpu__VBaa1155.h>
#include <rtlsim/Vsoc_wb_uart.h>

#include "soc.h"

RV_SOC::RV_SOC(const char* trace)
{
    m_soc = new Vsoc;
    m_tracePath = trace;
    m_ramSize = sizeof(m_soc->soc->ram0->ram0->mem) / wordSize;
    m_regFileSize = sizeof(m_soc->soc->cpu0->reg_inst->regfile) / wordSize;
    clearRam();
    reset();
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
    
void RV_SOC::enableVcdTrace()
{
    if (m_tracePath)
    {
        Verilated::traceEverOn(true);
        if (!m_trace) {
            delete m_trace;
        }
        m_trace = new VerilatedVcdC;
        m_soc->trace(m_trace, 99);
        m_trace->open(m_tracePath);
    }
}

void RV_SOC::tick(unsigned num)
{
    assert(m_soc);
    for (unsigned i = 0; i < num; i++)
    {

        if (m_tickCnt == 0) {

            m_soc->clk_i = 0;
            m_soc->eval();

            if (m_trace) {
                m_trace->dump(m_tickCnt);
            }

            m_tickCnt++;
            break;
        }
        en_state state_before = cpu_state();

        m_soc->clk_i = 1;
        m_soc->eval();
        if (m_trace) {
            m_trace->dump(m_tickCnt);
        }
        m_tickCnt++;

        m_soc->clk_i = 0;
        m_soc->eval();
        if (m_trace) {
            m_trace->dump(m_tickCnt);
            m_trace->flush();
        }
        m_tickCnt++;

        en_state state_after = cpu_state();
        if (    (state_before != state_after)
            &&  (state_after == en_state::FETCH)) {
            ++m_fetchCnt;
        }
    }
}

void RV_SOC::switchBusMasterToExternal(bool s)
{
    m_soc->bus_master_selector_i = s ? RV_SOC::busMaster::MASTER_EXT
                                     : RV_SOC::busMaster::MASTER_CPU;
}
    
void RV_SOC::toggleCpuReset(bool enReset)
{
    m_soc->cpu_rst_i = enReset;
}

void RV_SOC::writeWordExt(unsigned address, uint32_t val)
{
    if (address >= m_ramSize) {
        std::cerr << "writeWordExt: address " << std::dec << (address * 4) <<
            " (w_idx = 0x" <<  std::hex << address << ") is out of range " <<
            "[RamSize = " << std::dec << m_ramSize * 4 << " bytes]" << std::endl;
        throw std::out_of_range("write: the specified address is out of range");
    }
    unsigned wait = 20;
    m_soc->ext_tran_addr_i = address << 2;
    m_soc->ext_tran_data_i = val;
    m_soc->ext_tran_size_i = RV_SOC::extAccessSize::EXT_ACCESS_WORD;
    m_soc->ext_tran_write_i = 1;
    m_soc->ext_tran_start_i = 1;

    tick();
    m_soc->ext_tran_start_i = 0;
    m_soc->ext_tran_write_i = 0;

    bool success = false;
    for (unsigned i = wait; i >= 0; i--) {
        if (m_soc->ext_tran_ready_o) {
            success = true;
            break;
        }
        tick();
    }

    if (success) {
        m_soc->ext_tran_clear_i = 1;
        tick();
        m_soc->ext_tran_clear_i = 0;
    } else {
        std::cerr << "writeWordExt: no success result" << std::endl;
    }
}

uint32_t RV_SOC::readWordExt(unsigned address)
{
    if (address >= m_ramSize) {
        std::cerr << "readWordExt: address " << std::dec << (address * 4) <<
            " (w_idx = 0x" << std::hex << address << ") is out of range" <<
            "[RamSize = " << std::dec << m_ramSize * 4 << " bytes]" << std::endl;
        throw std::out_of_range("read: the specified address is out of range");
    }
    unsigned wait = 20;
    m_soc->ext_tran_addr_i = address << 2;
    m_soc->ext_tran_write_i = 0;
    m_soc->ext_tran_data_i = 0;
    m_soc->ext_tran_size_i = RV_SOC::extAccessSize::EXT_ACCESS_WORD;
    m_soc->ext_tran_start_i = 1;

    tick();
    m_soc->ext_tran_start_i = 0;
    m_soc->ext_tran_write_i = 0;

    bool success = false;
    for (unsigned i = wait; i >= 0; i--) {
        if (m_soc->ext_tran_ready_o) {
            success = true;
            break;
        }
        tick();
    }
    uint32_t data = 0;
    if (success) {
        m_soc->ext_tran_clear_i = 1;
        data = m_soc->ext_tran_data_o;
        tick();
        m_soc->ext_tran_clear_i = 0;
    } else {
        std::cerr << "readWordExt: no success result" << std::endl;
    }
    return data;
}

void RV_SOC::writeWord(unsigned address, uint32_t val)
{
    if (address >= m_ramSize) {
        std::cerr << "writeWord: address " << std::dec << (address * 4) <<
            " (w_idx = 0x" <<  std::hex << address << ") is out of range " <<
            "[RamSize = " << std::dec << m_ramSize * 4 << " bytes]" << std::endl;
        throw std::out_of_range("write: the specified address is out of range");
    }
    m_soc->soc->ram0->ram0->mem[address] = val;
}

uint32_t RV_SOC::readWord(unsigned address)
{
    if (address >= m_ramSize) {
        std::cerr << "readWord: address " << std::dec << (address * 4) <<
            " (w_idx = 0x" << std::hex << address << ") is out of range" <<
            "[RamSize = " << std::dec << m_ramSize * 4 << " bytes]" << std::endl;
        throw std::out_of_range("read: the specified address is out of range");
    }
    return m_soc->soc->ram0->ram0->mem[address];
}

void RV_SOC::reset()
{
    m_soc->rst_i = 1;
    m_soc->cpu_rst_i = 1;
    tick();
    m_soc->rst_i = 0;
    m_soc->cpu_rst_i = 0;
    tick();
}

uint64_t RV_SOC::getRamSize() const
{
    return m_ramSize;
}
    
uint64_t RV_SOC::getWordSize() const
{
    return wordSize;
}

void RV_SOC::writeReg(unsigned num, uint32_t val)
{
    assert(num < m_regFileSize);
    m_soc->soc->cpu0->reg_inst->regfile[num] = val;
}

uint32_t RV_SOC::readReg(unsigned num)
{
    assert(num < m_regFileSize);
    return m_soc->soc->cpu0->reg_inst->regfile[num];
}

uint32_t RV_SOC::getPC() const
{
    // assert(validPc());
    return m_soc->soc->cpu0->pc;
}

uint32_t RV_SOC::getRegFileSize() const
{
    return m_regFileSize;
}

void RV_SOC::clearRam()
{
    for (unsigned i = 0; i < m_ramSize; i++)
    {
        writeWord(i, 0);
    }
}
    
bool RV_SOC::validUartTransaction() const
{
    bool valid = (m_soc->soc->uart0->wb_cyc_i == m_soc->soc->uart0->wb_ack_o) && m_soc->soc->uart0->wb_cyc_i;
    return valid;
}

bool RV_SOC::validUartTxTransaction() const
{
    bool valid = validUartTransaction() && (m_soc->soc->uart0->wb_addr_i == UART_TX_ADDR);
    return valid;
}

bool RV_SOC::validUartRxTransaction() const
{
    bool valid = validUartTransaction() && (m_soc->soc->uart0->wb_addr_i == UART_RX_ADDR);
    return valid;
}

uint8_t RV_SOC::getUartTxData()
{
    assert(validUartTxTransaction());
    uint8_t data = ((m_soc->soc->uart0->wb_data_i) & 0xFF);
    return data;
}
    
bool RV_SOC::validPc() const
{
    bool valid =   (m_soc->soc->cpu0->state == (int)en_state::FETCH)
                && (m_soc->soc->cpu0->bus_inst->CYC_O)
                && (m_soc->soc->cpu0->bus_inst->ACK_I);
    return valid;
}

en_state RV_SOC::cpu_state() const
{
    return (en_state)(int)m_soc->soc->cpu0->state;
}
uint64_t RV_SOC::counterGetTick ()
{
    return  m_tickCnt;
}
uint64_t RV_SOC::counterGetStep ()
{
    return m_fetchCnt;
}

