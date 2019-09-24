#include "include/fpga.h"
#include <iostream>
#include <fcntl.h>

int main(int argc, char* argv[])
{
	if (argc < 3)
	{
		std::cerr << "You have to specify both FPGA file and reset state: <reset> <fpga> <bitstream>" << std::endl;
                return -1;
	}

	skFpga fpga(argv[1]);

	if (!fpga.IsOpened())
	{
		std::cerr << "Failed to open FPGA file: " << argv[1] << std::endl;
		return -1;
	}

        bool reset = atoi(argv[2]);
        std::cout << "Current reset state is " << fpga.GetResetPin() << ", setting new reset state to " << reset << std::endl;
        fpga.SetResetPin(reset);

        return 0;
}


