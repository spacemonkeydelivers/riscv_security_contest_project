#!/bin/bash

TEST_PATH="$1"
OUTPUT_PATH="$2"
export ZEPHYR_TOOLCHAIN_VARIANT=cross-compile
export CROSS_COMPILE="$3"
source zephyr-env.sh

set -o xtrace
west build -b beehive_riscv32 "${TEST_PATH}" --build-dir "${OUTPUT_PATH}"
