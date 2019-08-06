project(validation_tools)
include(ExternalProject)

if (SUBPROJECT_INSTALL_PREFIX)
    set(_SUBPROJECT_INSTALL_PREFIX "${SUBPROJECT_INSTALL_PREFIX}")
else()
    set(_SUBPROJECT_INSTALL_PREFIX install)
endif()

set(FLAGS "-march=rv32im -ffreestanding -nostdinc -nodefaultlibs -nostdlib -Os -Wall -Werror -Wextra")
ExternalProject_Add(
    libc
    CONFIGURE_COMMAND ""
    SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/libc"
    BUILD_COMMAND make
        -f "${CMAKE_CURRENT_SOURCE_DIR}/libc/Makefile"
        CFLAGS=${FLAGS}
        CC=/tank/work/dev/zephyr-sdk/0.10.0/riscv32-zephyr-elf/bin/riscv32-zephyr-elf-gcc
        AR=/tank/work/dev/zephyr-sdk/0.10.0/riscv32-zephyr-elf/bin/riscv32-zephyr-elf-ar
        INSTALL_DIR=${_SUBPROJECT_INSTALL_PREFIX}
        TOP=${CMAKE_CURRENT_SOURCE_DIR}/libc all install
    INSTALL_COMMAND ""
)

