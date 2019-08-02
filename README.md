# Zephyr builds and OVP/RTL models

Please refer to our [wiki](https://git.yggdrasill.ga/riscv_softcore_security_contest/riscv_core/wikis/home)
for information regarding build zephyr and a subsequent OVP/RTL boot procedures.

# riscv_core

**1. How to build & use:**
```
    1. mkdir build
    2. cd build
    3. cmake -DFIRMWARE_FILE=<data for RAM> ../
    4. make
    5. ./run_tests.py --test soc.py
```

**2. SoC memory map**  
    Memory map for this particular SoC is located in 32 bit address space and consists of:  
```
    0x00000000 : 0x3FFFFFFF - RAM address space. It's wrapped with RAM size.
    0x40000000 : 0x7FFFFFFF - Timer address space
    0x80000000 : 0xBFFFFFFF - Uart address space
    0xC0000000 : 0xFFFFFFFF - nothing mapped here yet
```

**3. How to work with timer**  
    3.1. On reset timer is not started  
    3.2. Any write to the timer address space sets the timer threshold to the
    written value and starts the timer  
    3.3. Writing 0 to the timer address space stops the timer   
    3.4. Any read to the timer address space resets the current timer value  
    **TODO: add test for working with timer and test CPU's IRQ**  
    
**4. Using converter from asm to hex**  
```
    4.1. set path to PATH=$PATH:/tank/work/dev/toolchains/riscv32-newlib-gcc/bin/  
    4.2. run python3 bench/compile_asm.py --toolchain riscv32-unknown-elf- --input tests/asm/byte_test.s --output-dir /tmp/ --linker bench/soc.ld --tmp-dir /tmp  
    4.3. use /tmp/test_byte.hex as hex input for tests
```
