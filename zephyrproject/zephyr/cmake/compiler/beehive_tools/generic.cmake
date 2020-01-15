# SPDX-License-Identifier: Apache-2.0

set_ifndef(CC clang)

find_program(CMAKE_C_COMPILER ${BEEHIVE_LLVM_PREFIX}/${CC} NO_DEFAULT_PATH)

if(CMAKE_C_COMPILER STREQUAL CMAKE_C_COMPILER-NOTFOUND)
  message(FATAL_ERROR "Zephyr was unable to find the toolchain. Is the environment misconfigured?
User-configuration:
ZEPHYR_TOOLCHAIN_VARIANT: ${ZEPHYR_TOOLCHAIN_VARIANT}
Internal variables:
RISCV_GCC_PREFIX: ${RISCV_GCC_PREFIX}
BEEHIVE_LLVM_PREFIX: ${BEEHIVE_LLVM_PREFIX}
")
endif()

execute_process(
  COMMAND ${CMAKE_C_COMPILER} --version
  RESULT_VARIABLE ret
  OUTPUT_QUIET
  ERROR_QUIET
  )
if(ret)
  message(FATAL_ERROR "Executing the below command failed. Are permissions set correctly?
'${CMAKE_C_COMPILER} --version'
"
    )
endif()
