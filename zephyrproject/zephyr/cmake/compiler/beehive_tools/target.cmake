# SPDX-License-Identifier: Apache-2.0

set_ifndef(C++ g++)

# Configures CMake for using GCC, this script is re-used by several
# GCC-based toolchains

set(CROSS_LLVM_CC  "${BEEHIVE_LLVM_PREFIX}/clang")
set(CROSS_LLVM_CXX "${BEEHIVE_LLVM_PREFIX}/clang++")

assert_exists(CROSS_LLVM_CXX)
assert_exists(CROSS_LLVM_CC)

find_program(CROSS_GCC_CC     ${RISCV_GCC_PREFIX}gcc      NO_DEFAULT_PATH)
find_program(CROSS_GCC_CXX    ${RISCV_GCC_PREFIX}g++      NO_DEFAULT_PATH)
find_program(CMAKE_OBJCOPY    ${RISCV_GCC_PREFIX}objcopy  NO_DEFAULT_PATH)
find_program(CMAKE_OBJDUMP    ${RISCV_GCC_PREFIX}objdump  NO_DEFAULT_PATH)
find_program(CMAKE_AS         ${RISCV_GCC_PREFIX}as       NO_DEFAULT_PATH)
find_program(CMAKE_LINKER     ${RISCV_GCC_PREFIX}gcc      NO_DEFAULT_PATH)
find_program(CMAKE_AR         ${RISCV_GCC_PREFIX}ar       NO_DEFAULT_PATH)
find_program(CMAKE_RANLIB     ${RISCV_GCC_PREFIX}ranlib   NO_DEFAULT_PATH)
find_program(CMAKE_READELF    ${RISCV_GCC_PREFIX}readelf  NO_DEFAULT_PATH)
find_program(CMAKE_GDB        ${RISCV_GCC_PREFIX}gdb      NO_DEFAULT_PATH)
find_program(CMAKE_NM         ${RISCV_GCC_PREFIX}nm       NO_DEFAULT_PATH)

assert_exists(CROSS_GCC_CC)

# HACK: in order to override linker one has to set CMAKE_LINKER and CMAKE_C_LINK_EXECUTABLE
set(CMAKE_C_LINK_EXECUTABLE "<CMAKE_LINKER> <FLAGS> <CMAKE_CXX_LINK_FLAGS> <LINK_FLAGS> <OBJECTS> -o <TARGET> <LINK_LIBRARIES>")

set(CMAKE_C_COMPILER   ${CROSS_LLVM_CC})
set(CMAKE_CXX_COMPILER ${CROSS_LLVM_CXX})

set(NOSTDINC "")

# Note that NOSYSDEF_CFLAG may be an empty string, and
# set_ifndef() does not work with empty string.
if(NOT DEFINED NOSYSDEF_CFLAG)
  set(NOSYSDEF_CFLAG -undef)
endif()

foreach(file_name include include-fixed)
  execute_process(
    COMMAND ${CMAKE_C_COMPILER} --print-file-name=${file_name}
    OUTPUT_VARIABLE _OUTPUT
    )
  string(REGEX REPLACE "\n" "" _OUTPUT "${_OUTPUT}")

  list(APPEND NOSTDINC ${_OUTPUT})
endforeach()

include(${ZEPHYR_BASE}/cmake/gcc-m-cpu.cmake)

if("${ARCH}" STREQUAL "arm")
  list(APPEND TOOLCHAIN_C_FLAGS
    -mthumb
    -mcpu=${GCC_M_CPU}
    )
  list(APPEND TOOLCHAIN_LD_FLAGS
    -mthumb
    -mcpu=${GCC_M_CPU}
    )

  include(${ZEPHYR_BASE}/cmake/fpu-for-gcc-m-cpu.cmake)

  if(CONFIG_FLOAT)
    list(APPEND TOOLCHAIN_C_FLAGS -mfpu=${FPU_FOR_${GCC_M_CPU}})
    list(APPEND TOOLCHAIN_LD_FLAGS -mfpu=${FPU_FOR_${GCC_M_CPU}})
    if    (CONFIG_FP_SOFTABI)
      list(APPEND TOOLCHAIN_C_FLAGS -mfloat-abi=softfp)
      list(APPEND TOOLCHAIN_LD_FLAGS -mfloat-abi=softfp)
    elseif(CONFIG_FP_HARDABI)
      list(APPEND TOOLCHAIN_C_FLAGS -mfloat-abi=hard)
      list(APPEND TOOLCHAIN_LD_FLAGS -mfloat-abi=hard)
    endif()
  endif()
elseif("${ARCH}" STREQUAL "arc")
  list(APPEND TOOLCHAIN_C_FLAGS
    -mcpu=${GCC_M_CPU}
    )
endif()

if(NOT no_libgcc)
  # This libgcc code is partially duplicated in compiler/*/target.cmake
  execute_process(
    COMMAND ${CROSS_GCC_CC} ${TOOLCHAIN_C_FLAGS} --print-libgcc-file-name
    OUTPUT_VARIABLE LIBGCC_FILE_NAME
    OUTPUT_STRIP_TRAILING_WHITESPACE
    )

  assert_exists(LIBGCC_FILE_NAME)

  get_filename_component(LIBGCC_DIR ${LIBGCC_FILE_NAME} DIRECTORY)

  assert_exists(LIBGCC_DIR)

  LIST(APPEND LIB_INCLUDE_DIR "-L\"${LIBGCC_DIR}\"")
  LIST(APPEND TOOLCHAIN_LIBS gcc)

  execute_process(
    COMMAND ${CROSS_GCC_CC} ${TOOLCHAIN_C_FLAGS}  -print-sysroot
    OUTPUT_VARIABLE GCC_SYSROOT_DIR
    OUTPUT_STRIP_TRAILING_WHITESPACE
    )
  assert_exists(GCC_SYSROOT_DIR)
  set(LIBC_HEADER_PATH "${GCC_SYSROOT_DIR}/include")
  assert_exists(LIBC_HEADER_PATH)
endif()

if(SYSROOT_DIR)
  # The toolchain has specified a sysroot dir that we can use to set
  # the libc path's
  execute_process(
    COMMAND ${CROSS_GCC_CC} ${TOOLCHAIN_C_FLAGS} --print-multi-directory
    OUTPUT_VARIABLE NEWLIB_DIR
    OUTPUT_STRIP_TRAILING_WHITESPACE
    )

  set(LIBC_LIBRARY_DIR "\"${SYSROOT_DIR}\"/lib/${NEWLIB_DIR}")
  set(LIBC_INCLUDE_DIR ${SYSROOT_DIR}/include)
endif()


# For CMake to be able to test if a compiler flag is supported by the
# toolchain we need to give CMake the necessary flags to compile and
# link a dummy C file.
#
# CMake checks compiler flags with check_c_compiler_flag() (Which we
# wrap with target_cc_option() in extentions.cmake)
foreach(isystem_include_dir ${NOSTDINC})
  list(APPEND isystem_include_flags -isystem "\"${isystem_include_dir}\"")
endforeach()
# The CMAKE_REQUIRED_FLAGS variable is used by check_c_compiler_flag()
# (and other commands which end up calling check_c_source_compiles())
# to add additional compiler flags used during checking. These flags
# are unused during "real" builds of Zephyr source files linked into
# the final executable.
#
# Appending onto any existing values lets users specify
# toolchain-specific flags at generation time.
list(APPEND CMAKE_REQUIRED_FLAGS
  -nostartfiles
  -nostdlib ${isystem_include_flags}
  -Wl,--unresolved-symbols=ignore-in-object-files)
#list(APPEND CMAKE_REQUIRED_FLAGS -nostartfiles -nostdlib ${isystem_include_flags} -Wl,--unresolved-symbols=ignore-in-object-files)
string(REPLACE ";" " " CMAKE_REQUIRED_FLAGS "${CMAKE_REQUIRED_FLAGS}")

# Load toolchain_cc-family macros
include(${ZEPHYR_BASE}/cmake/compiler/gcc/target_security_fortify.cmake)
include(${ZEPHYR_BASE}/cmake/compiler/gcc/target_security_canaries.cmake)
include(${ZEPHYR_BASE}/cmake/compiler/gcc/target_optimizations.cmake)
include(${ZEPHYR_BASE}/cmake/compiler/gcc/target_cpp.cmake)
include(${ZEPHYR_BASE}/cmake/compiler/gcc/target_asm.cmake)
include(${ZEPHYR_BASE}/cmake/compiler/gcc/target_baremetal.cmake)
