project(secure_sw_models)
include(ExternalProject)

if (SUBPROJECT_INSTALL_PREFIX)
    set(_SUBPROJECT_INSTALL_PREFIX "${SUBPROJECT_INSTALL_PREFIX}")
else()
    set(_SUBPROJECT_INSTALL_PREFIX install)
endif()

set(SPIKE_SRC_DIR "${CMAKE_CURRENT_SOURCE_DIR}/beehive-riscv-isa-sim")
ExternalProject_Add(
    spike
    CONFIGURE_COMMAND ${SPIKE_SRC_DIR}/configure --prefix=${_SUBPROJECT_INSTALL_PREFIX}
    SOURCE_DIR "${SPIKE_SRC_DIR}"
    BUILD_ALWAYS True
    BUILD_COMMAND $(MAKE)
    INSTALL_COMMAND $(MAKE) install
)

