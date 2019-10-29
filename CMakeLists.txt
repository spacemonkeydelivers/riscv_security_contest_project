# Specify the minimum version for CMake
cmake_minimum_required(VERSION 3.12)

enable_testing()

# Project's name
project(riscv_soc)

set(DEFAULT_ARCH_C_TESTS "rv32ic")
set(DEFAULT_ARCH_ASM_TESTS "rv32imc")
set(DEFAULT_ARCH_COMPLIANCE_TESTS "rv32imc")
set(DEFAULT_ARCH_ZEPHYR_TESTS "rv32imc") # this one is not used at the moment
# DO NOT USE!!!
option(BUILD_OVP_MODELS "Build OVP VLNV library (Imperas installation is required)" OFF)

set(PLATFORM_FILES_ROOT "${CMAKE_BINARY_DIR}/distrib/platform")
set(MODELS_FILES_ROOT "${CMAKE_BINARY_DIR}/distrib/models")

# Set the output folder where your program will be created
set(EXECUTABLE_OUTPUT_PATH ${PLATFORM_FILES_ROOT}/bin)
set(LIBRARY_OUTPUT_PATH ${PLATFORM_FILES_ROOT}/lib)

find_package(Python2 COMPONENTS Interpreter Development)
message("-- Checking that all required python libraries are installed...")
execute_process(COMMAND "${Python2_EXECUTABLE}" -uB "${CMAKE_SOURCE_DIR}/cmake/checks/python.py"
                RESULT_VARIABLE "PYTHON_LIBS_CHECKED")

if (NOT ${PYTHON_LIBS_CHECKED} EQUAL 0)
    message(FATAL_ERROR "could not detect the required python libraries")
endif()

find_package(Boost COMPONENTS python)

if (NOT DEFINED ENV{RISCV_TOOLCHAIN_PATH})
    set(RISCV_TOOLCHAIN_PATH /tank/work/dev/toolchains/riscv32imc-llvm/)
    message("RISCV_TOOLCHAIN_PATH is NOT set, using the default value: ${RISCV_TOOLCHAIN_PATH}")
    if (NOT EXISTS "${RISCV_TOOLCHAIN_PATH}")
        message(FATAL_ERROR "No toolchain was detected at the default path, please set RISCV_TOOLCHAIN_PATH")
    endif()
else()
    set(RISCV_TOOLCHAIN_PATH $ENV{RISCV_TOOLCHAIN_PATH})
endif()

set(RV_CC "clang")
if (NOT EXISTS "${RV_TOOLCHAIN_PATH}/bin/${RISCV_CC}")
    message(FATAL_ERROR "Could not find compiler for risc-v: ${RV_TOOLCHAIN_PATH}/bin/${RV_CC}\nPlease set RISCV_TOOLCHAIN_PATH appropriately")
endif()

set(RV_NM "llvm-nm")
if (NOT EXISTS "${RV_TOOLCHAIN_PATH}/bin/${RISCV_NM}")
    message(FATAL_ERROR "Could not find nm tool for risc-v: ${RV_TOOLCHAIN_PATH}/bin/${RV_NM}\nPlease set RISCV_TOOLCHAIN_PATH appropriately")
endif()

set(RV_AR "llvm-ar")
if (NOT EXISTS "${RV_TOOLCHAIN_PATH}/bin/${RISCV_AR}")
    message(FATAL_ERROR "Could not find ar tool for risc-v: ${RV_TOOLCHAIN_PATH}/bin/${RV_AR}\nPlease set RISCV_TOOLCHAIN_PATH appropriately")
endif()

set(RV_LD "riscv32-unknown-elf-gcc")
find_program(LD_PATH NAMES ${RV_LD} PATHS $ENV)
if (NOT EXISTS ${LD_PATH})
    message(FATAL_ERROR "Could not find gcc toolchain for risc-v: ${RV_LD}\nPlease set RISCV_TOOLCHAIN_PATH appropriately")
endif()

set(RV_OBJCOPY "riscv32-unknown-elf-objcopy")
find_program(OBJCOPY_PATH NAMES ${RV_OBJCOPY} PATHS $ENV)
if (NOT EXISTS ${OBJCOPY_PATH})
    message(FATAL_ERROR "Could not find gcc toolchain for risc-v: ${RV_OBJCOPY}\nPlease set RISCV_TOOLCHAIN_PATH appropriately")
endif()

set(WEST_TEST_PATH "${CMAKE_SOURCE_DIR}/zephyrproject/.west/config")
if(EXISTS "${WEST_TEST_PATH}")
    set (ENABLE_ZEPHYR_APPS True)
    message("working zephyr/west configuration detected, zephyr apps ENABLED")
else()
    set (ENABLE_ZEPHYR_APPS False)
    message("WARNING: could not detect working zephyr/west configuration, zephyr apps DISABLED")
endif()

find_program(VERILATOR_BIN verilator)
find_path(VERILATOR_INCLUDE verilated.h
    PATH_SUFFIXES verilator/include
    HINTS /usr/share
)

if (${VERILATOR_BIN} MATCHES "NOTFOUND" OR ${VERILATOR_INCLUDE} MATCHES "NOTFOUND")
    message(FATAL_ERROR "Could not find verilator.")
endif()

set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++17 -Wall -g")

# VERILATOR_* is used to build verilator library and RLT simulator
set(VERILATOR_FLAGS "--trace --trace-params --trace-structs")
set(VERILATOR_FLAGS "${VERILATOR_FLAGS} -Wall --MMD --public")
set(VERILATOR_FLAGS "${VERILATOR_FLAGS} -CFLAGS -g -CFLAGS -fpic")

# This produce "verilated" library, consumed by RTL simulator
include(cmake/VerilatorLibrary.cmake)
# Produces RTL simulator, testbench and platform_headers
# NOTE: any interaction with RTL simulator should go through testbench and platform_headers
include(cmake/VerilatedRTL.cmake)

# tools expect that platform headers are available
set(SUBPROJECT_INSTALL_PREFIX "${CMAKE_BINARY_DIR}/distrib/tools")
add_subdirectory("${CMAKE_CURRENT_SOURCE_DIR}/bench/tools")

# OVP
if (BUILD_OVP_MODELS)
    set(SUBPROJECT_INSTALL_PREFIX "${CMAKE_BINARY_DIR}/distrib/models/ovp/")
    add_subdirectory(models/ovp/)
endif()

include(cmake/TestRunners.cmake)

if (ENABLE_ZEPHYR_APPS)
    include(cmake/ZephyrApplications.cmake)
else()
    set(ZEPHYR_APPS "")
endif()

include(tests/TestLists.txt)

