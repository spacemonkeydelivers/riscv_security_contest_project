# compile verilator lib =====
set(VERILATOR_LIBRARY verilated)
set(VERILATED_SOURCE_LIST
    verilated.cpp
    verilated_save.cpp
)
if (VERILATOR_FLAGS MATCHES "trace")
    set(VERILATED_SOURCE_LIST ${VERILATED_SOURCE_LIST} verilated_vcd_c.cpp)
endif()

foreach(src ${VERILATED_SOURCE_LIST})
    set(VERILATED_SOURCES ${VERILATED_SOURCES} ${VERILATOR_INCLUDE}/${src})
endforeach()

add_library(${VERILATOR_LIBRARY} SHARED ${VERILATED_SOURCES})
target_include_directories(${VERILATOR_LIBRARY} SYSTEM PUBLIC ${VERILATOR_INCLUDE})
target_include_directories(${VERILATOR_LIBRARY} SYSTEM PUBLIC ${VERILATOR_INCLUDE}/vltstd/)

install(TARGETS verilated LIBRARY DESTINATION lib)

