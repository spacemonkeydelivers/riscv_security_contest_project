# Specify the minimum version for CMake
cmake_minimum_required(VERSION 3.12)

enable_testing()

# Project's name
project(riscv_soc)

set(SUPPORTED_RISCV_ARCH "rv32i")
# DO NOT USE!!!
option(BUILD_OVP_MODELS "Build OVP VLNV library (Imperas installation is required)" OFF)

set(PLATFORM_FILES_ROOT "${CMAKE_BINARY_DIR}/distrib/platform")
set(MODELS_FILES_ROOT "${CMAKE_BINARY_DIR}/distrib/models")

# Set the output folder where your program will be created
set(EXECUTABLE_OUTPUT_PATH ${PLATFORM_FILES_ROOT}/bin)
set(LIBRARY_OUTPUT_PATH ${PLATFORM_FILES_ROOT}/lib)

#if(CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
#  set(CMAKE_INSTALL_PREFIX ${CMAKE_BINARY_DIR}/install CACHE PATH "..." FORCE)
#endif()
# SET(CMAKE_INSTALL_RPATH "${LIBRARY_OUTPUT_PATH}")

find_package(Python2 COMPONENTS Interpreter Development)
find_package(Boost COMPONENTS python)

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
set(VERILATOR_FLAGS "${VERILATOR_FLAGS} -Wall -Wno-UNDRIVEN -Wno-UNUSED -Wno-WIDTH --MMD --public -Wno-MODDUP")
set(VERILATOR_FLAGS "${VERILATOR_FLAGS} -CFLAGS -g -CFLAGS -fpic")
set(VERILATOR_FLAGS_POST "-Wno-lint")

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
include(tests/TestLists.txt)

