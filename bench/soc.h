#ifndef D_SOC___INLCUDE_HEADER_GUARD__
#define D_SOC___INCLUDE_HEADER_GUARD__

#include <cstdint>

class Vsoc;
class VerilatedVcdC;

class RV_SOC
{
public:

    static const unsigned wordSize = 4;

    void tick(unsigned num = 1);
    RV_SOC(const char* trace = nullptr);
    ~RV_SOC();

    void reset();

    void writeWord(unsigned address, uint32_t val);
    uint32_t readWord(unsigned address);

    void writeReg(unsigned num, uint32_t val);
    uint32_t readReg(unsigned num);

    uint64_t getRamSize() const;
    uint64_t getWordSize() const;
    uint32_t getPC() const;
    uint32_t getRegFileSize() const;

private:
    Vsoc*          m_soc         {nullptr};
    uint64_t       m_tickCnt     {0};
    VerilatedVcdC* m_trace       {nullptr};

    uint64_t       m_ramSize     {0};
    uint64_t       m_regFileSize {0};
};

#endif //D_SOC___INCLUDE_HEADER_GUARD__

