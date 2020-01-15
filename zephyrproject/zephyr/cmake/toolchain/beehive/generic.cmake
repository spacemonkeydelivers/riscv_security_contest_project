# SPDX-License-Identifier: Apache-2.0

# CROSS_COMPILE is a KBuild mechanism for specifying an external
# toolchain with a single environment variable.
#
# It is a legacy mechanism that will in Zephyr translate to
# specififying ZEPHYR_TOOLCHAIN_VARIANT to 'cross-compile' with the location
# 'CROSS_COMPILE'.
#
# New users should set the env var 'ZEPHYR_TOOLCHAIN_VARIANT' to
# 'cross-compile' and the 'CROSS_COMPILE' env var to the toolchain
# prefix. This interface is consisent with the other non-"Zephyr SDK"
# toolchains.
#
# It can be set from either the environment or from a CMake variable
# of the same name.
#
# The env var has the lowest precedence.

set_ifndef(BEEHIVE_LLVM_PREFIX "$ENV{BEEHIVE_LLVM_PREFIX}")
set(BEEHIVE_LLVM_PREFIX "${BEEHIVE_LLVM_PREFIX}/" CACHE PATH "")
assert(BEEHIVE_LLVM_PREFIX "BEEHIVE_LLVM_PREFIX is not set")

set_ifndef(RISCV_GCC_PREFIX "$ENV{RISCV_GCC_PREFIX}")
set(RISCV_GCC_PREFIX ${RISCV_GCC_PREFIX} CACHE PATH "")
assert(RISCV_GCC_PREFIX "RISCV_GCC_PREFIX is not set")

set(COMPILER beehive_tools)
