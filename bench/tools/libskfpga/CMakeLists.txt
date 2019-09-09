set(MODULE_NAME "libskfpga")
cmake_minimum_required(VERSION 3.13)

set(SRC_PATH          ${CMAKE_SOURCE_DIR}/src)
set(INC_PATH          ${CMAKE_SOURCE_DIR})
set(EXEC_OUTPUT_PATH  ${CMAKE_BINARY_DIR}/bin)
set(LIB_OUTPUT_PATH   ${CMAKE_BINARY_DIR}/lib)

set(LIBSKFPGA_LIB_SRC      "${SRC_PATH}/fpga.cpp")
set(LIBSKFPGA_LOADER_SRC   "${SRC_PATH}/fpga_loader.cpp")
set(LIBSKFPGA_LIB          "skfpga")
set(LIBSKFPGA_LOADER       "fpga_loader")
set(LIBSKFPGA_READER_SRC   "${SRC_PATH}/fpga_reader.cpp")
set(LIBSKFPGA_READER       "fpga_reader")
set(LIBSKFPGA_WRITER_SRC   "${SRC_PATH}/fpga_writer.cpp")
set(LIBSKFPGA_WRITER       "fpga_writer")
set(LIBSKFPGA_RESET_SRC    "${SRC_PATH}/fpga_reset.cpp")
set(LIBSKFPGA_RESET        "fpga_reset")

find_package(Python2 COMPONENTS Interpreter Development)                                            
find_package(Boost COMPONENTS python) 


# This one is important
SET(CMAKE_SYSTEM_NAME Linux)

# Specify the cross compiler
SET(CMAKE_C_COMPILER   /tank/work/dev/toolchains/arm-at91-linux-gnueabi/bin/arm-at91-linux-gnueabi-gcc)
SET(CMAKE_CXX_COMPILER /tank/work/dev/toolchains/arm-at91-linux-gnueabi/bin/arm-at91-linux-gnueabi-g++)

# Where is the target environment
SET(CMAKE_FIND_ROOT_PATH  /tank/work/dev/toolchains/arm-at91-linux-gnueabi/arm-at91-linux-gnueabi/ /tank/work/dev/toolchains/arm-at91-linux-gnueabi/)

# Search for programs in the build host directories
SET(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)

# For libraries and headers in the target directories
SET(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
SET(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)


# Building static library #
add_library(${LIBSKFPGA_LIB} STATIC ${LIBSKFPGA_LIB_SRC})
target_include_directories(${LIBSKFPGA_LIB} PUBLIC ${INC_PATH})
#set_target_properties(${LIBSKFPGA_LIB} PROPERTIES
#    LIBRARY_OUTPUT_DIRECTORY ${LIBSKFPGA_LIB_OUTPUT}
#)

# Building loader #
ADD_EXECUTABLE(${LIBSKFPGA_LOADER} ${LIBSKFPGA_LOADER_SRC}) 
TARGET_LINK_LIBRARIES(${LIBSKFPGA_LOADER} ${LIBSKFPGA_LIB})

# Building writer #
ADD_EXECUTABLE(${LIBSKFPGA_WRITER} ${LIBSKFPGA_WRITER_SRC}) 
TARGET_LINK_LIBRARIES(${LIBSKFPGA_WRITER} ${LIBSKFPGA_LIB})

# Building reader #
ADD_EXECUTABLE(${LIBSKFPGA_READER} ${LIBSKFPGA_READER_SRC}) 
TARGET_LINK_LIBRARIES(${LIBSKFPGA_READER} ${LIBSKFPGA_LIB})

# Building reset #
ADD_EXECUTABLE(${LIBSKFPGA_RESET} ${LIBSKFPGA_RESET_SRC}) 
TARGET_LINK_LIBRARIES(${LIBSKFPGA_RESET} ${LIBSKFPGA_LIB})

# Set a list of sources
set(PYTHON_LIB_SRC ${LIBSKFPGA_LIB_SRC} src/ui.cpp)

add_library(bench SHARED ${PYTHON_LIB_SRC})
target_include_directories(bench PUBLIC
    ${INC_PATH}
    ${Python2_INCLUDE_DIRS}
    ${Boost_INCLUDE_DIRS}
)

target_link_libraries(bench
    ${Boost_LIBRARIES}
    ${Python2_LIBRARIES}
)

#if (NOT DEFINED SOC_RAM_SIZE)
#    set(SOC_RAM_SIZE 65536)
#endif()
#
#add_custom_command(
#    OUTPUT ${CMAKE_BINARY_DIR}/tmp/mem_img.hex
#    DEPENDS ${CMAKE_SOURCE_DIR}/bench/tools/build/makehex.py
#    COMMAND dd if=/dev/zero of=mem_img.raw bs=1 count=${SOC_RAM_SIZE}
#    COMMAND ${Python2_EXECUTABLE}
#            ${CMAKE_SOURCE_DIR}/bench/tools/build/makehex.py
#            ${CMAKE_BINARY_DIR}/tmp/mem_img.raw
#            ${CMAKE_BINARY_DIR}/tmp/mem_img.hex
#    WORKING_DIRECTORY ${CMAKE_BINARY_DIR}/tmp
#    VERBATIM
#)
#
#if (NOT DEFINED MEM_FILE)
#    set(MEM_FILE ${CMAKE_BINARY_DIR}/tmp/mem_img.hex)
#endif()
#
#separate_arguments(VERILATOR_ARGS_LIST
#                   WINDOWS_COMMAND "${VERILATOR_FLAGS} -I${RTL_SRC_PATH}")
#separate_arguments(VERILATOR_ARGS_POST_LIST
#                   WINDOWS_COMMAND "${VERILATOR_FLAGS_POST}")
#add_custom_command(
#    OUTPUT ${VERILOG_OUTPUT_LIB}
#    DEPENDS ${RTL_SRC_FILES} ${MEM_FILE}
#    COMMAND ${VERILATOR_BIN} ${VERILATOR_ARGS_LIST}
#        -GFIRMWARE_FILE="${MEM_FILE}"
#        -GSOC_RAM_SIZE=${SOC_RAM_SIZE}
#        -Wall
#        -cc
#        -Mdir ${RTL_MODEL_BUILD_PATH}
#        ${RTL_SRC_PATH}/soc.v
#        --top-module ${MODULE_NAME}
#        ${VERILATOR_ARGS_POST_LIST}
#    COMMAND cd ${RTL_MODEL_BUILD_PATH} && make -f V${MODULE_NAME}.mk
#    WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
#    VERBATIM
#)
#set_directory_properties(PROPERTY
#    ADDITIONAL_MAKE_CLEAN_FILES
#    ${RTL_MODEL_BUILD_PATH})
#
#add_custom_target(
#    Vmodel ALL
#    DEPENDS "${VERILOG_OUTPUT_LIB}"
#    WORKING_DIRECTORY "${RTL_MODEL_BUILD_PATH}"
#)
#
#set(PLATFORM_HEADERS_DIR ${PLATFORM_FILES_ROOT}/include/platform)
#file(MAKE_DIRECTORY "${PLATFORM_HEADERS_DIR}")
#set(SOC_ENUMS "${PLATFORM_HEADERS_DIR}/soc_enums.h")
#add_custom_command(
#    OUTPUT "${SOC_ENUMS}"
#    COMMAND DISTRIB_TOOLS_SHARE=${CMAKE_BINARY_DIR}/distrib/tools/share
#            ${Python2_EXECUTABLE}
#            ${CMAKE_SOURCE_DIR}/bench/tools/build/gen_enums.py
#            ${CMAKE_SOURCE_DIR} > "${SOC_ENUMS}"
#    WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
#    DEPENDS ${CMAKE_SOURCE_DIR}/bench/tools/build/gen_enums.py
#            ${CMAKE_SOURCE_DIR}/rtl/cpu/cpu.v
#    VERBATIM
#)
#add_custom_target(
#    platform_headers ALL
#    DEPENDS "${SOC_ENUMS}"
#)
#
## Set a list of sources
#set(TESTBENCH_SRC bench/rtl/soc.cpp bench/rtl/ui.cpp)
#
#add_library(bench SHARED ${TESTBENCH_SRC})
#add_dependencies(bench Vmodel platform_headers)
#target_include_directories(bench PUBLIC
#    ${VERILATOR_INCLUDE}
#    ${VERILATOR_INCLUDE}/vltstd
#    ${RTL_MODEL_BUILD_ROOT}
#    ${PLATFORM_FILES_ROOT}/include
#    ${Python2_INCLUDE_DIRS}
#    ${Boost_INCLUDE_DIRS}
#)
#
#target_link_libraries(bench
#    ${Boost_LIBRARIES}
#    ${Python2_LIBRARIES}
#    ${VERILOG_OUTPUT_LIB}
#    ${VERILATOR_LIBRARY}
#)
#install(TARGETS bench LIBRARY DESTINATION lib)

