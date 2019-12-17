
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
if(ENABLE_ASSERTS)
    set(VERILATOR_FLAGS "${VERILATOR_FLAGS} --assert")
endif()
if(ENABLE_VCD_TRACING)
    set(VERILATOR_FLAGS "${VERILATOR_FLAGS} --trace --trace-params --trace-structs")
endif()
if(ENABLE_THREADING)
    set(VERILATOR_FLAGS "${VERILATOR_FLAGS} --threads 1")
endif()
set(VERILATOR_FLAGS "${VERILATOR_FLAGS} --MMD -O3 -Wall -Wno-UNUSED")
set(VERILATOR_FLAGS "${VERILATOR_FLAGS}
    -CFLAGS -fpic
    -CFLAGS -O3
    -CFLAGS -fno-stack-protector
    -CFLAGS -fstrict-aliasing
    -CFLAGS -fbranch-probabilities
    -CFLAGS -flto
    -LDFLAGS -flto")

