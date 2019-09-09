#include "include/fpga.h"
#include <iostream>
#include <fcntl.h>

int main(int argc, char* argv[])
{
	if (argc < 3)
	{
		std::cerr << "You have to specify both FPGA file and bitstream file: <loader> <fpga> <bitstream>" << std::endl;
                return -1;
	}

	skFpga fpga(argv[1]);

	if (!fpga.IsOpened())
	{
		std::cerr << "Failed to open FPGA file: " << argv[1] << std::endl;
		return -1;
	}

	if (fpga.UploadBitstream(argv[2]))
	{
		std::cerr << "Failed to upload bitstream file: " << argv[2] << std::endl;
		return -1;
	}

        skFpga::sk_fpga_smc_timings t;
        fpga.ReadSMCTimings(&t);
        std::cout << "Setup 0x" << std::hex << t.setup << std::endl;
        std::cout << "Pulse 0x" << std::hex << t.pulse << std::endl;
        std::cout << "cycle 0x" << std::hex << t.cycle << std::endl;
        std::cout << "mode 0x" << std::hex << t.mode << std::endl;
        std::cout << "cs 0x" << std::hex << t.cs << std::endl;

        t.setup = 0x01010101;
        t.pulse = 0x0a0a0a0a;
        t.cycle = 0x000e000e;
        fpga.SetupSMCTimings(t);


        return 0;
}

