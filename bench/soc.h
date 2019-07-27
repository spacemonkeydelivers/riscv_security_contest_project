#ifndef D_SOC___INLCUDE_HEADER_GUARD__
#define D_SOC___INCLUDE_HEADER_GUARD__

#include <cstdint>

class Vsoc;
class VerilatedVcdC;

class RV_SOC
{
public:
    enum class MemOpcode
    {
        READB = 0,
        READBU = 1,
        READH = 2,
        READHU = 3,
        READW = 4,
        WRITEB = 5,
        WRITEH = 6,
        WRITEW = 7
    };

    static const unsigned wordSize = 4;

    void tick(unsigned num = 1);
    RV_SOC(const char* trace = nullptr);
    ~RV_SOC();

    void dumpRam(unsigned start = 0, unsigned size = wordSize);
    void reset();

    uint32_t doMemOp(unsigned address, MemOpcode opcode, uint32_t value = 0);
private:
    Vsoc*          m_soc     {nullptr};
    uint64_t       m_tickCnt {0};
    VerilatedVcdC* m_trace   {nullptr};
};

#endif //D_SOC___INCLUDE_HEADER_GUARD__

