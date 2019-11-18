# Specify the minimum version for CMake
cmake_minimum_required(VERSION 3.12)
enable_testing()
# Project's name
project(riscv_soc)

if (NOT EXISTS "${CMAKE_SOURCE_DIR}/.updated_marker")
    message(FATAL_ERROR "submodules are not initialized, please run "
                        "`${CMAKE_SOURCE_DIR}/update_submodules.sh`")
endif()

set(DEFAULT_ARCH_C_TESTS "rv32imc")
# asm tests must be compiled without C option, because some tests naively
# assume that instructions are of 4 bytes length
set(DEFAULT_ARCH_ASM_TESTS "rv32im")
# complience tests should be compiled without C option, whenever a compressed
# instruction is needed they provice compressed instruction explicitly
set(DEFAULT_ARCH_COMPLIANCE_TESTS "rv32im")
set(DEFAULT_ARCH_ZEPHYR_TESTS "rv32imc") # this one is not used at the moment
# DO NOT USE!!!
option(BUILD_OVP_MODELS "Build OVP VLNV library (Imperas installation is required)" OFF)

set(PLATFORM_FILES_ROOT "${CMAKE_BINARY_DIR}/distrib/platform")
set(MODELS_FILES_ROOT "${CMAKE_BINARY_DIR}/distrib/models")

# Set the output folder where your program will be created
set(EXECUTABLE_OUTPUT_PATH ${PLATFORM_FILES_ROOT}/bin)
set(LIBRARY_OUTPUT_PATH ${PLATFORM_FILES_ROOT}/lib)

include(cmake/tools/python.cmake)
include(cmake/tools/toolchain.cmake)
include(cmake/tools/verilator.cmake)

set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++17 -Wall -g")

# This produce "verilated" library, consumed by RTL simulator
include(cmake/VerilatorLibrary.cmake)
# Produces RTL simulator, testbench and platform_headers
# NOTE: any interaction with RTL simulator should go through testbench and platform_headers
include(cmake/VerilatedRTL.cmake)

# tools expect that platform headers are available
set(SUBPROJECT_INSTALL_PREFIX "${CMAKE_BINARY_DIR}/distrib/tools")

# build auxiliary suporting tools (like libc)
add_subdirectory("${CMAKE_CURRENT_SOURCE_DIR}/bench/tools")
# build auxiliary SW models
add_subdirectory(models)

# OVP
if (BUILD_OVP_MODELS)
    set(SUBPROJECT_INSTALL_PREFIX "${CMAKE_BINARY_DIR}/distrib/models/ovp/")
    add_subdirectory(models/ovp/)
endif()

include(cmake/TestRunners.cmake)

set(WEST_TEST_PATH "${CMAKE_SOURCE_DIR}/zephyrproject/.west/config")
if(EXISTS "${WEST_TEST_PATH}")
    message("working zephyr/west configuration detected, zephyr apps ENABLED")
    set (ENABLE_ZEPHYR_APPS True)
    include(cmake/ZephyrApplications.cmake)
else()
    message("WARNING: could not detect working zephyr/west configuration, zephyr apps DISABLED")
    set (ENABLE_ZEPHYR_APPS False)
    set(ZEPHYR_APPS "")
endif()

include(tests/TestLists.txt)

