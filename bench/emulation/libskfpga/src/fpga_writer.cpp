#include "include/fpga.h"
#include <iostream>
#include <fcntl.h>
#include <string>

int main(int argc, char* argv[])
{
	if (argc < 4)
	{
		std::cerr << "You have to specify both FPGA address and value to write in hex: <writer> <fpga> <addr> <value>" << std::endl;
                return -1;
	}

	skFpga fpga(argv[1]);

	if (!fpga.IsOpened())
	{
		std::cerr << "Failed to open FPGA file: " << argv[1] << std::endl;
		return -1;
	}
        
        uint32_t addr = std::stoul(std::string(argv[2]), nullptr, 16);
        uint16_t data = std::stoul(std::string(argv[3]), nullptr, 16);

        std::cout << "Writing to address 0x" << std::hex << addr << std::dec << " data 0x"  << std::hex << data << std::endl;

        fpga.WriteShort(addr, data);
        return 0;
}
