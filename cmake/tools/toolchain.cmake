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

set(RV_CC_PATH "${RISCV_LLVM_TOOLCHAIN_PATH}/bin/clang")
set(RV_NM_PATH "${RISCV_LLVM_TOOLCHAIN_PATH}/bin/llvm-nm")
set(RV_AR_PATH "${RISCV_LLVM_TOOLCHAIN_PATH}/bin/llvm-ar")

foreach(tool ${RV_CC_PATH}
             ${RV_NM_PATH}
             ${RV_AR_PATH})
  if (NOT EXISTS "${tool}")
    message(FATAL_ERROR "Could not find compiler for risc-v: "
            "${tool}\n"
            "Please set RISCV_TOOLCHAIN_PATH appropriately")
  endif()
endforeach(tool)

set(RV_LD "riscv32-unknown-elf-gcc")
set(RV_OBJCOPY "riscv32-unknown-elf-objcopy")

find_program(RV_LD_PATH NAMES ${RV_LD})
find_program(RV_OBJCOPY_PATH NAMES ${RV_OBJCOPY})
if (NOT EXISTS ${RV_LD_PATH})
    message(FATAL_ERROR "${RV_LD} is not detected in PATH :(\n"
            "Please make sure that a proper gcc toolchain is available")
endif()
if (NOT EXISTS ${RV_OBJCOPY_PATH})
    message(FATAL_ERROR "${RV_OBJCOPY} is not detected in PATH :(\n"
            "Please make sure that a proper gcc toolchain is available")
endif()

