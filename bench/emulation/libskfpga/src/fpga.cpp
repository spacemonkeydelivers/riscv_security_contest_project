#include "include/fpga.h"
#include "include/fpga_ioctl.h"

#include <unistd.h>

#include <cassert>
#include <iostream>
#include <fcntl.h>


// open fpga file
skFpga::skFpga(const char* path)
{
	m_fd = open(path, O_RDWR);
	assert(IsOpened());
}

// close fpga file
skFpga::~skFpga()
{
	assert(IsOpened());
	close(m_fd);
	m_fd = 0;
}

bool skFpga::UploadBitstream(const char* bs)
{
	constexpr int buf_size = 4096;
	uint8_t buf[buf_size];
	ssize_t nrd = 0;
	// assert fpga is opened
	assert(IsOpened());
	int bs_fd = open(bs, O_RDONLY);
	if (!(bs_fd > 0))
	{
		std::cerr << "Failed to open bitstream file: " << bs << std::endl;
		return true;
	}

	FpgaProgrammingStart();
	while (nrd = read(bs_fd, buf, buf_size))
	{
	    write(m_fd, buf, nrd);
	}
	close(bs_fd);
	bool res = FpgaProgrammingFinish();
	if (res)
	{
		std::cerr << "Failed to upload bitstream file: " << bs << std::endl;
		return true;
	}
	return false;
}

void skFpga::WriteShort(uint32_t addr, uint16_t data)
{
	SetAddrSel(addr);
	sk_fpga_data d = {addr, data};
	ioctl(m_fd, SKFPGA_SHORT_WRITE, &d) == -1;
}

uint16_t skFpga::ReadShort(uint32_t addr)
{
	SetAddrSel(addr);
	sk_fpga_data d = {addr, 0};
	bool res = (ioctl(m_fd, SKFPGA_SHORT_READ, &d) == -1);
	return d.data;
}

void skFpga::SetResetPin(bool state)
{
	uint8_t val = static_cast<uint8_t>(state);
	ioctl(m_fd, SKFPGA_RESET_WRITE, &val) == -1;
}

bool skFpga::GetResetPin()
{
	uint8_t res;
	(ioctl(m_fd, SKFPGA_RESET_READ, &res) == -1);
	return static_cast<bool>(res);
}

void skFpga::SetIRQPin(bool state)
{
	uint8_t val = static_cast<uint8_t>(state);
	ioctl(m_fd, SKFPGA_FPGA_IRQ_WRITE, &val) == -1;
}

bool skFpga::GetIRQPin()
{
	uint8_t res;
	(ioctl(m_fd, SKFPGA_FPGA_IRQ_READ, &res) == -1);
	return static_cast<bool>(res);
}

void skFpga::FpgaProgrammingStart()
{
	(ioctl(m_fd, SKFPGA_PROG_START) == -1);
}

bool skFpga::FpgaProgrammingFinish()
{
	uint8_t res = 0;
	(ioctl(m_fd, SKFPGA_PROG_FINISH, &res) == -1);
	return res;
}

void skFpga::SetAddrSel(uint32_t addr)
{
	fpga_addr_selector properSel = (addr > m_address_window_size) ? FPGA_ADDR_CS1 : FPGA_ADDR_CS0;
	if (properSel != m_curAddrSel)
	{
		m_curAddrSel = properSel;
		uint32_t val = static_cast<uint32_t>(m_curAddrSel);
		(ioctl(m_fd, SKFPGA_ADDR_SEL_WRITE, &val) == -1);
	}
}

void skFpga::SetupSMCTimings(sk_fpga_smc_timings t)
{
	(ioctl(m_fd, SKFPGA_SMC_TIMINGS_WRITE, &t) == -1);
}

void skFpga::ReadSMCTimings(sk_fpga_smc_timings* t)
{
	(ioctl(m_fd, SKFPGA_SMC_TIMINGS_READ, t) == -1);
}

bool skFpga::IsOpened() const
{
    return m_fd > 0;
}
