project(validation_tools)
include(ExternalProject)

if (SUBPROJECT_INSTALL_PREFIX)
    set(_SUBPROJECT_INSTALL_PREFIX "${SUBPROJECT_INSTALL_PREFIX}")
else()
    set(_SUBPROJECT_INSTALL_PREFIX install)
endif()

set(FLAGS "-ffreestanding -nostdinc -nodefaultlibs -nostdlib -Os -Wall -Werror -Wextra")
set(FLAGS "${FLAGS} -I${PLATFORM_FILES_ROOT}/include")
set(FLAGS "${FLAGS} -march=${DEFAULT_ARCH_C_TESTS}")
ExternalProject_Add(
    libc
    CONFIGURE_COMMAND ""
    DEPENDS platform_headers
    SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/libc"
    BUILD_ALWAYS True
    BUILD_COMMAND $(MAKE)
        -f "${CMAKE_CURRENT_SOURCE_DIR}/libc/Makefile"
        CFLAGS=${FLAGS}
        CC=${RV_LLVM_CC_PATH}
        AR=${RV_LLVM_AR_PATH}
        INSTALL_DIR=${_SUBPROJECT_INSTALL_PREFIX}
        TOP=${CMAKE_CURRENT_SOURCE_DIR}/libc all install test_program VERBOSE=1
    INSTALL_COMMAND ""
)

set(LIBM_C_FLAGS "${FLAGS} -w -I${_SUBPROJECT_INSTALL_PREFIX}/include")
ExternalProject_Add(
    libm
    CONFIGURE_COMMAND ""
    DEPENDS platform_headers libc
    SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/fdlibm"
    BUILD_ALWAYS True
    BUILD_COMMAND $(MAKE)
        -f "${CMAKE_CURRENT_SOURCE_DIR}/fdlibm/__dummy_Makefile"
        C_FLAGS=${LIBM_C_FLAGS}
        C_COMPILER=${RV_LLVM_CC_PATH}
        AR=${RV_LLVM_AR_PATH}
        INSTALL_DIR=${_SUBPROJECT_INSTALL_PREFIX}
        TOP=${CMAKE_CURRENT_SOURCE_DIR}/fdlibm
        install VERBOSE=1
    INSTALL_COMMAND ""
)

configure_file("${CMAKE_CURRENT_SOURCE_DIR}/misc/testsMakefile.include.in"
               "${_SUBPROJECT_INSTALL_PREFIX}/share/testsMakefile.include")

