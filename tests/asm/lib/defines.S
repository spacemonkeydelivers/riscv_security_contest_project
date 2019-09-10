#ifndef D_RISCV_SOC_TESTS_DEFINES_INCLUDE_GUARD
#define D_RISCV_SOC_TESTS_DEFINES_INCLUDE_GUARD

#define TARGET "RTL"

#define TAG_V0  0
#define TAG_V1  1
#define TAG_V2  2
#define TAG_V3  3
#define TAG_V4  4
#define TAG_V5  5
#define TAG_V6  6
#define TAG_V7  7
#define TAG_V8  8
#define TAG_V9  9
#define TAG_V10 10
#define TAG_V11 11
#define TAG_V12 12
#define TAG_V13 13
#define TAG_V14 14
#define TAG_V15 15

#define TAG_CTRL_ENABLE (1 << 0)
#define TAG_CTRL_IACK   (1 << 1)
#define TAG_CTRL_ICHECK_ENABLE (1 << 2)

.ifdef __test_exit
  .purgem __test_exit
.endif

.macro __test_exit status:req, target
  // ra contains "return code"
  li ra, \status
#ifdef ENABLE_FPGA_EXIT
  // this is FPGA-friendly exit sequence
  la t1, __marker_test_status
  sw ra, 0(t1)

  la t1, __marker_test_end
  li t2, 0xbaddad
  sw t2, 0(t1)
#endif //ENABLE_FPGA_EXIT
1:
  j 1b
  wfi
.endm

.ifdef PASSED
   .purgem PASSED
.endif

.macro PASSED
   __test_exit 0x0A11C001, TARGET
.endm

.ifdef FAILED
   .purgem FAILED
.endif

.macro FAILED status:req
  .ifeq \status
    .error "FAILED status must be non-zero"
  .endif
   __test_exit \status, TARGET
.endm

#define UART_BASE_ADDR 0x80000003

#define GRANULE_TAG_WIDTH 4
#define TAG_OFFSET (32 - 2 - GRANULE_TAG_WIDTH)

#define SET_TAG(sdst, tmp, tag) li tmp, (~(0xf << TAG_OFFSET)); \
    and sdst, sdst, tmp ; \
    slli tmp, tag, TAG_OFFSET ; \
    or sdst, tmp, sdst
#define ON_EXCEPTION .balign 4; ON_EXCEPTION_handler

#endif // D_RISCV_SOC_TESTS_DEFINES_INCLUDE_GUARD

