
find_program(VERILATOR_BIN verilator)
find_path(VERILATOR_INCLUDE verilated.h
    PATH_SUFFIXES verilator/include
    HINTS /usr/share
)

if (${VERILATOR_BIN} MATCHES "NOTFOUND" OR ${VERILATOR_INCLUDE} MATCHES "NOTFOUND")
    message(FATAL_ERROR "Could not find verilator.")
endif()

# VERILATOR_* is used to build verilator library and RLT simulator
set(VERILATOR_FLAGS "")
if(ENABLE_VCD_TRACING)
    set(VERILATOR_FLAGS "${VERILATOR_FLAGS} --trace --trace-params --trace-structs")
endif()
set(VERILATOR_FLAGS "${VERILATOR_FLAGS} -Wall --MMD --public -O3")
set(VERILATOR_FLAGS "${VERILATOR_FLAGS} -CFLAGS -fpic")

