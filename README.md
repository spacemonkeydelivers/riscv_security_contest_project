# Zephyr builds and OVP/RTL models

Please refer to our [wiki](https://git.yggdrasill.ga/riscv_softcore_security_contest/riscv_core/wikis/home)
for information regarding build zephyr and a subsequent OVP/RTL boot procedures.

# Testing

## Running

To run test use the following command

```
ctest -R "expr_to_match_test_name"
```

If you want to run with **tracing** enable, use the following command:

```
 DBG="+trace" ctest -R lb -V
```


## Debugging

Please refer to this [Debugging infrastructure](https://git.yggdrasill.ga/riscv_softcore_security_contest/riscv_core/wikis/Debug-Infrastructure#the-debugger)

## TODO:

make this exit sequence compatible with compliance tests. That is we should
eventually switch to ecall/scall.

# riscv_core

**1. How to build & use:**
```
    1. mkdir build
    2. cd build
    3. RISCV_TOOLCHAIN=<path to riscv toolchain> cmake -DSOC_RAM_SIZE=65536 $TRUNK
    # NOTE_1: D_SOC_RAM_SIZE can be less, but conformance and some c tests need at least 64K to work
    # NOTE_2: The value for RISCV_TOOLCHAIN is expected to be '/tank/work/dev/toolchains/riscv32i-newlib-gcc/
    4. make -j8
    5. ctest -j8
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

**4. Building toolchain for the project**  
    4.1. Please refer to https://git.yggdrasill.ga/riscv_softcore_security_contest/riscv-gnu-toolchain  
    4.2. git clone --recursive https://git.yggdrasill.ga/riscv_softcore_security_contest/riscv-gnu-toolchain  
    4.3. cd riscv-gnu-toolchain  
    4.4. ./configure --prefix=<install path> --with-arch=rv32i --with-abi=ilp32  
    4.5. make newlib -j20  
    4.6. Get your toolchain with support for memory tagging instructions in <install path>  

# Used open source components

| name       | purpose  | git | license |
| ----       | -------  | --- | ------- |
| Tiny printf | libc: printf implementation | [github](https://github.com/mpaland/printf) | MIT |
| __moddi3/__divdi3 | libc: sw division from libgcc | [github mirror](https://github.com/gcc-mirror/gcc/tree/master/libgcc) | GPL2+ |
| __mulsi3 | libc: sw multiplication | [github mirror](https://github.com/gcc-mirror/gcc/blob/master/libgcc/config/epiphany/mulsi3.c) | GPL2+ |

