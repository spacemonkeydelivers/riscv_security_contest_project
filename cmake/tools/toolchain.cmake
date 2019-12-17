if (NOT DEFINED RISCV_LLVM_TOOLCHAIN_PATH)

    set(RISCV_LLVM_TOOLCHAIN_PATH /tank/work/dev/toolchains/riscv32imc-llvm)
    message("RISCV_LLVM_TOOLCHAIN_PATH is NOT set, using the default value: "
        "${RISCV_LLVM_TOOLCHAIN_PATH}")

    if (NOT EXISTS "${RISCV_LLVM_TOOLCHAIN_PATH}")
        message(FATAL_ERROR "No toolchain was detected at the default path, "
            "please set RISCV_LLVM_TOOLCHAIN_PATH")
    endif()
else()
    message("using toolchain from <${RISCV_LLVM_TOOLCHAIN_PATH}> (specified by user)")
endif()

set(RV_LLVM_CC_PATH      "${RISCV_LLVM_TOOLCHAIN_PATH}/bin/clang")
#set(RV_LLVM_LD_PATH      "${RISCV_LLVM_TOOLCHAIN_PATH}/bin/llvm-lld")
set(RV_LLVM_NM_PATH      "${RISCV_LLVM_TOOLCHAIN_PATH}/bin/llvm-nm")
set(RV_LLVM_AR_PATH      "${RISCV_LLVM_TOOLCHAIN_PATH}/bin/llvm-ar")
set(RV_LLVM_OBJCOPY_PATH "${RISCV_LLVM_TOOLCHAIN_PATH}/bin/llvm-objcopy")

# TODO: add lld ${RV_LLVM_LD_PATH}
foreach(tool ${RV_LLVM_CC_PATH}
             ${RV_LLVM_NM_PATH}
             ${RV_LLVM_AR_PATH}
             ${RV_LLVM_OBJCOPY_PATH})
  if (NOT EXISTS "${tool}")
    message(FATAL_ERROR "Could not find compiler for risc-v: "
            "${tool}\n"
            "Please set RISCV_TOOLCHAIN_PATH appropriately")
  endif()
endforeach(tool)

if (NOT DEFINED RISCV_GCC_TOOLCHAIN_PATH)

    set(RISCV_GCC_TOOLCHAIN_PATH /tank/work/dev/toolchains/riscv32imc-tags-newlib-gcc)
    message("RISCV_GCC_TOOLCHAIN_PATH is NOT set, using the default value: "
        "${RISCV_GCC_TOOLCHAIN_PATH}")

    if (NOT EXISTS "${RISCV_GCC_TOOLCHAIN_PATH}")
        message(FATAL_ERROR "No toolchain was detected at the default path, "
            "please set RISCV_GCC_TOOLCHAIN_PATH")
    endif()
else()
    message("using toolchain from <${RISCV_GCC_TOOLCHAIN_PATH}> (specified by user)")
endif()

set(RV_GCC_CC_PATH "${RISCV_GCC_TOOLCHAIN_PATH}/bin/riscv32-unknown-elf-gcc")
set(RV_GCC_LD_PATH "${RISCV_GCC_TOOLCHAIN_PATH}/bin/riscv32-unknown-elf-ld")
set(RV_GCC_NM_PATH "${RISCV_GCC_TOOLCHAIN_PATH}/bin/riscv32-unknown-elf-nm")
set(RV_GCC_AR_PATH "${RISCV_GCC_TOOLCHAIN_PATH}/bin/riscv32-unknown-elf-ar")
set(RV_GCC_OBJCOPY_PATH "${RISCV_GCC_TOOLCHAIN_PATH}/bin/riscv32-unknown-elf-objcopy")

foreach(tool ${RV_GCC_CC_PATH}
             ${RV_GCC_LD_PATH}
             ${RV_GCC_NM_PATH}
             ${RV_GCC_AR_PATH}
             ${RV_GCC_OBJCOPY_PATH})
  if (NOT EXISTS "${tool}")
    message(FATAL_ERROR "${tool} is not detected in PATH :(\n"
            "Please make sure that a proper gcc toolchain is available")
  endif()
endforeach(tool)

execute_process(COMMAND ${RV_GCC_CC_PATH} -print-libgcc-file-name
                OUTPUT_VARIABLE RV_LIBGCC_PATH
                OUTPUT_STRIP_TRAILING_WHITESPACE)
if (NOT EXISTS ${RV_LIBGCC_PATH})
    message(FATAL_ERROR "${RV_LIBGCC_PATH} (libgcc) was not detected :(\n"
        "Please make sure that your toolchain distribution "
        " (gcc) is bundled with libgcc")
endif()

