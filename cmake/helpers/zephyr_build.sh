#!/bin/bash

TEST_PATH="$1"
OUTPUT_PATH="$2"

export ZEPHYR_TOOLCHAIN_VARIANT=beehive
export RISCV_GCC_PREFIX="$3"
export BEEHIVE_LLVM_PREFIX="$4"

source zephyr-env.sh

set -o xtrace
west build -b beehive_riscv32 "${TEST_PATH}" --build-dir "${OUTPUT_PATH}"
