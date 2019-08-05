make \
    CC=/tank/work/dev/zephyr-sdk/0.10.0/riscv32-zephyr-elf/bin/riscv32-zephyr-elf-gcc \
    AR=/tank/work/dev/zephyr-sdk/0.10.0/riscv32-zephyr-elf/bin/riscv32-zephyr-elf-ar \
    TOP=/home/ecco/sec/riscv_core/bench/tools/libc \
    CFLAGS='-march=rv32im -ffreestanding -nostdinc -nodefaultlibs -nostdlib -Os -Wall -Werror -Wextra' \
    -f /home/ecco/sec/riscv_core/bench/tools/libc/Makefile \
    all

