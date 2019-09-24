#include "include/fpga.h"
#include <iostream>
#include <fcntl.h>
#include <string>

int main(int argc, char* argv[])
{
	if (argc < 3)
	{
		std::cerr << "You have to specify both FPGA address to read in hex: <writer> <fpga> <addr>" << std::endl;
                return -1;
	}

	skFpga fpga(argv[1]);

	if (!fpga.IsOpened())
	{
		std::cerr << "Failed to open FPGA file: " << argv[1] << std::endl;
		return -1;
	}
        
        uint32_t addr = std::stoul(std::string(argv[2]), nullptr, 16);
        uint16_t data = fpga.ReadShort(addr);

        std::cout << "Read address 0x" << std::hex << addr << std::dec << " data 0x"  << std::hex << data << std::endl;
        return 0;
}
