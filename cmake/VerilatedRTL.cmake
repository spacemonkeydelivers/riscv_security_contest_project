set(MODULE_NAME "soc")

set(RTL_SRC_PATH            ${CMAKE_SOURCE_DIR}/rtl)
set(RTL_MODEL_BUILD_ROOT    ${CMAKE_BINARY_DIR}/rtl_model)
set(RTL_MODEL_BUILD_PATH    ${RTL_MODEL_BUILD_ROOT}/rtlsim)

file(MAKE_DIRECTORY ${RTL_MODEL_BUILD_PATH})
file(GLOB_RECURSE RTL_SRC_FILES
     ${RTL_SRC_PATH}/*.v
)

set(VERILOG_OUTPUT_LIB "${RTL_MODEL_BUILD_PATH}/V${MODULE_NAME}__ALL.a")

set(SIZE_8K   8192)
set(SIZE_16K  16384)
set(SIZE_32K  32768)
set(SIZE_64K  65536)
set(SIZE_128K 131072)
set(SIZE_256K 262144)
if (NOT DEFINED SOC_RAM_SIZE)
    set(SOC_RAM_SIZE ${SIZE_128K})
endif()

add_custom_command(
    OUTPUT ${CMAKE_BINARY_DIR}/tmp/mem_img.hex
    DEPENDS ${CMAKE_SOURCE_DIR}/bench/tools/build/makehex.py
    COMMAND dd if=/dev/zero of=mem_img.raw bs=1 count=${SOC_RAM_SIZE}
    COMMAND ${Python2_EXECUTABLE}
            ${CMAKE_SOURCE_DIR}/bench/tools/build/makehex.py
            ${CMAKE_BINARY_DIR}/tmp/mem_img.raw
            ${CMAKE_BINARY_DIR}/tmp/mem_img.hex
    WORKING_DIRECTORY ${CMAKE_BINARY_DIR}/tmp
    VERBATIM
)

if (NOT DEFINED MEM_FILE)
    set(MEM_FILE ${CMAKE_BINARY_DIR}/tmp/mem_img.hex)
endif()

separate_arguments(VERILATOR_ARGS_LIST
                   WINDOWS_COMMAND "${VERILATOR_FLAGS} -I${RTL_SRC_PATH}")
separate_arguments(VERILATOR_ARGS_POST_LIST
                   WINDOWS_COMMAND "${VERILATOR_FLAGS_POST}")
add_custom_command(
    OUTPUT ${VERILOG_OUTPUT_LIB}
    DEPENDS ${RTL_SRC_FILES} ${MEM_FILE}
    COMMAND ${VERILATOR_BIN} ${VERILATOR_ARGS_LIST}
        -GFIRMWARE_FILE="${MEM_FILE}"
        -GSOC_RAM_SIZE=${SOC_RAM_SIZE}
        -DSIMULATION_RUN
        -Wall
        -cc
        -Mdir ${RTL_MODEL_BUILD_PATH}
        ${RTL_SRC_PATH}/soc.v
        --top-module ${MODULE_NAME}
        ${VERILATOR_ARGS_POST_LIST}
    COMMAND cd ${RTL_MODEL_BUILD_PATH} && make -f V${MODULE_NAME}.mk
    WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
    VERBATIM
)
set_directory_properties(PROPERTY
    ADDITIONAL_MAKE_CLEAN_FILES
    ${RTL_MODEL_BUILD_PATH})

add_custom_target(
    Vmodel ALL
    DEPENDS "${VERILOG_OUTPUT_LIB}"
    WORKING_DIRECTORY "${RTL_MODEL_BUILD_PATH}"
)

set(PLATFORM_HEADERS_DIR ${PLATFORM_FILES_ROOT}/include/platform)
file(MAKE_DIRECTORY "${PLATFORM_HEADERS_DIR}")
set(SOC_ENUMS "${PLATFORM_HEADERS_DIR}/soc_enums.h")
add_custom_command(
    OUTPUT "${SOC_ENUMS}"
    COMMAND DISTRIB_TOOLS_SHARE=${CMAKE_BINARY_DIR}/distrib/tools/share
            ${Python2_EXECUTABLE}
            ${CMAKE_SOURCE_DIR}/bench/tools/build/gen_enums.py
            ${CMAKE_SOURCE_DIR} > "${SOC_ENUMS}"
    WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
    DEPENDS ${CMAKE_SOURCE_DIR}/bench/tools/build/gen_enums.py
            ${CMAKE_SOURCE_DIR}/rtl/cpu/cpu.v
    VERBATIM
)
add_custom_target(
    platform_headers ALL
    DEPENDS "${SOC_ENUMS}"
)
set(VMODEL_INCLUDES_HEADER "${RTL_MODEL_BUILD_ROOT}/Vsoc_includes.h")
add_custom_command(
    OUTPUT "${VMODEL_INCLUDES_HEADER}"
    COMMAND find rtlsim/ -name 'Vsoc*.h' | sed 's/^/\#include </' | sed 's/$$/>/' >Vsoc_includes.h
    WORKING_DIRECTORY ${RTL_MODEL_BUILD_ROOT}
    DEPENDS ${RTL_SRC_FILES}
)
add_custom_target(
    generate_vsoc_enums
    DEPENDS "${VMODEL_INCLUDES_HEADER}" Vmodel
)

# Set a list of sources
set(TESTBENCH_SRC bench/rtl/libsim/soc.cpp bench/rtl/libsim/ui.cpp bench/rtl/libsim/uart.cpp)

add_library(dut SHARED ${TESTBENCH_SRC})
target_compile_options(dut PUBLIC "-DD_SOC_RAM_SIZE=${SOC_RAM_SIZE}")
add_dependencies(dut Vmodel platform_headers generate_vsoc_enums)
target_include_directories(dut PUBLIC
    ${VERILATOR_INCLUDE}
    ${VERILATOR_INCLUDE}/vltstd
    ${RTL_MODEL_BUILD_ROOT}
    ${PLATFORM_FILES_ROOT}/include
    ${Python2_INCLUDE_DIRS}
    ${Boost_INCLUDE_DIRS}
)

target_link_libraries(dut
    ${Boost_LIBRARIES}
    ${Python2_LIBRARIES}
    ${VERILOG_OUTPUT_LIB}
    ${VERILATOR_LIBRARY}
)
install(TARGETS dut LIBRARY DESTINATION lib)

