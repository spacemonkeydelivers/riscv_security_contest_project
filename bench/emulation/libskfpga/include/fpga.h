#ifndef INCLUDE_FPGA_H_
#define INCLUDE_FPGA_H_

#include <errno.h>
#include <cstdint>

class skFpga
{
public:

    struct sk_fpga_smc_timings
    {
        uint32_t setup; // setup ebi timings
        uint32_t pulse; // pulse ebi timings
        uint32_t cycle; // cycle ebi timings
        uint32_t mode;  // ebi mode
        uint8_t  cs;    // cs
    };

    skFpga() = delete;
    skFpga(const char* path);

    ~skFpga();

    bool UploadBitstream(const char* bs);

    void WriteShort(uint32_t addr, uint16_t data);
    uint16_t ReadShort(uint32_t addr);

    void SetResetPin(bool state);
    bool GetResetPin();

    void SetIRQPin(bool state);
    bool GetIRQPin();

    bool IsOpened() const;

    void SetupSMCTimings(sk_fpga_smc_timings t);
    void ReadSMCTimings(sk_fpga_smc_timings* t);
private:

    enum fpga_addr_selector
    {
        FPGA_ADDR_UNDEFINED = 0,
        FPGA_ADDR_CS0,
        FPGA_ADDR_CS1,
        FPGA_ADDR_DMA,
        FPGA_ADDR_LAST,
    };

    struct sk_fpga_data
    {
        uint32_t address;
        uint16_t data;
    };


	// sets proper address selector based on address
	void SetAddrSel(uint32_t addr);

	void FpgaProgrammingStart();
	bool FpgaProgrammingFinish();


    int m_fd = -EFAULT;
    const unsigned m_address_window_size = 32 * 1024 * 1024;
    fpga_addr_selector m_curAddrSel = FPGA_ADDR_UNDEFINED;
};


#endif
