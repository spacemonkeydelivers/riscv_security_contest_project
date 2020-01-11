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

set(MTE_FLAGS "")

add_custom_target(clink ALL
   COMMAND ${CMAKE_COMMAND} -E make_directory "${_SUBPROJECT_INSTALL_PREFIX}/share/"
   COMMAND ${CMAKE_COMMAND} -E copy ${CMAKE_CURRENT_SOURCE_DIR}/libc/share/soc.ld ${_SUBPROJECT_INSTALL_PREFIX}/share/
   DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/libc/share/soc.ld"
)
add_custom_target(libc ALL DEPENDS clink)

function(addlibc_target target_name)
    set(LIBC_C_FLAGS "${FLAGS}")
    set(LIBC_INSTALL_DIR "${_SUBPROJECT_INSTALL_PREFIX}/libc/${target_name}")
    set(LIBC_TGT_NAME "libc_${target_name}")
    add_dependencies(libc ${LIBC_TGT_NAME})
    ExternalProject_Add(
        libc_${target_name}
        CONFIGURE_COMMAND ""
        DEPENDS platform_headers
        SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/libc"
        BUILD_ALWAYS True
        BUILD_COMMAND $(MAKE)
            -f "${CMAKE_CURRENT_SOURCE_DIR}/libc/Makefile"
            CFLAGS=${LIBC_C_FLAGS}
            CC=${RV_LLVM_CC_PATH}
            LD=${RV_GCC_LD_PATH}
            AR=${RV_LLVM_AR_PATH}
            INSTALL_DIR=${LIBC_INSTALL_DIR}
            CONFIGURATION=${target_name}
            TOP=${CMAKE_CURRENT_SOURCE_DIR}/libc all install test_program VERBOSE=1
        INSTALL_COMMAND ""
    )

    set(LIBM_C_FLAGS "${LIBC_C_FLAGS} -w -I${LIBC_INSTALL_DIR}/include")
    set(LIBM_INSTALL_DIR "${_SUBPROJECT_INSTALL_PREFIX}/libm/${target_name}")
    set(LIBM_TGT_NAME "libm_${target_name}")
    add_dependencies(libc ${LIBM_TGT_NAME})
    ExternalProject_Add(
        libm_${target_name}
        CONFIGURE_COMMAND ""
        DEPENDS platform_headers ${LIBC_TGT_NAME}
        SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/fdlibm"
        BUILD_ALWAYS True
        BUILD_COMMAND $(MAKE)
            -f "${CMAKE_CURRENT_SOURCE_DIR}/fdlibm/Makefile"
            C_FLAGS=${LIBM_C_FLAGS}
            C_COMPILER=${RV_LLVM_CC_PATH}
            AR=${RV_LLVM_AR_PATH}
            LD=${RV_GCC_LD_PATH}
            INSTALL_DIR=${LIBM_INSTALL_DIR}
            TOP=${CMAKE_CURRENT_SOURCE_DIR}/fdlibm
            install VERBOSE=1
        INSTALL_COMMAND ""
    )
endfunction()

addlibc_target("tm")
addlibc_target("ns")
addlibc_target("mte")


configure_file("${CMAKE_CURRENT_SOURCE_DIR}/misc/testsMakefile.include.in"
               "${_SUBPROJECT_INSTALL_PREFIX}/share/testsMakefile.include")

