#ifndef INCLUDE_FPGA_IOCTL_H_
#define INCLUDE_FPGA_IOCTL_H_

#include <sys/ioctl.h>
#include <cstdint>

#define SKFP_IOC_MAGIC 0x81

// ioctl to write data to FPGA
#define SKFPGA_SHORT_WRITE _IOW(SKFP_IOC_MAGIC, 1, sk_fpga_data)
// ioctl to read data from FPGA
#define SKFPGA_SHORT_READ _IOR(SKFP_IOC_MAGIC, 2, sk_fpga_data)

// ioctl to set SMC timings
#define SKFPGA_SMC_TIMINGS_WRITE _IOW(SKFP_IOC_MAGIC, 3, sk_fpga_smc_timings)
// ioctl to request SMC timings
#define SKFPGA_SMC_TIMINGS_READ _IOR(SKFP_IOC_MAGIC, 4, sk_fpga_smc_timings)

// ioctl to start programming FPGA
#define SKFPGA_PROG_START _IO(SKFP_IOC_MAGIC, 5)
// ioctl to finish programming FPGA
#define SKFPGA_PROG_FINISH _IOR(SKFP_IOC_MAGIC, 7, uint8_t)

// ioctl to set reset pin level
#define SKFPGA_RESET_WRITE _IOW(SKFP_IOC_MAGIC, 8, uint8_t)
// ioctl to get reset pin level
#define SKFPGA_RESET_READ _IOR(SKFP_IOC_MAGIC, 9, uint8_t)

// ioctl to set arm-to-fpga pin level
#define SKFPGA_FPGA_IRQ_WRITE _IOW(SKFP_IOC_MAGIC, 10, uint8_t)
// ioctl to get arm-to-fpga pin level
#define SKFPGA_FPGA_IRQ_READ _IOR(SKFP_IOC_MAGIC, 11, uint8_t)

// ioctl to set proper address space
#define SKFPGA_ADDR_SEL_WRITE _IOW(SKFP_IOC_MAGIC, 12, uint32_t)
// ioctl to get current address space
#define SKFPGA_ADDR_SEL_READ _IOR(SKFP_IOC_MAGIC, 13, uint32_t)

#endif /* INCLUDE_FPGA_IOCTL_H_ */
