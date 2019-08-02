
#define TARGET "RTL"

.ifdef __test_exit
  .purgem __test_exit
.endif

.macro __test_exit status:req, target
  // TODO: implement a proper test exit sequence
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
   __test_exit \status, TARGET
.endm

