#define TARGET "RTL"

.ifdef __test_exit
  .purgem __test_exit
.endif

.macro __test_exit status:req, target
  // TODO: implement a proper test exit sequence
  li ra, \status
1:
  j 1b
  wfi
.endm

.ifdef PASSED
   .purgem PASSED
.endif

.macro PASSED
   __test_exit 0, TARGET
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

