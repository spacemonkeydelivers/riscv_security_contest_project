# Overview

This repository is a publically-available copy of a work performed by a team
of SW engineers in an attempt to participate in
[RISCV security contest](https://riscv.org/2019/07/risc-v-softcpu-core-contest).


This repository contains:

1. HDL design (verilog) of an  **rv32imc-compliant** RISC-V core integrated in a
custom SOC. The soc is called "beehive-riscv!".
1. Our design introduces new extension to support **HW memory tagging**. The
   design of an extension is documented [here](doc/arch/memtag.md).
1. To enhance the security even further, our soc provides HW generator of
pseudo-random numbers (LFSR-based). SW routines may want to use this register
to generate random memory tags.
1. Testing infrastructure and libraries used to test the design. This includes
scripts to enable simulation (verilator) and emulation (an fpga by xilinx).
1. Design documents used for development.
1. A copy of zephyr OS for RISV platform with a set of custom patches enhancing
(at least we hope so) security.
1. The project also requires **GNU toolchain with a set of custom patches**. It
   is available from this
[sattelite repository](https://github.com/spacemonkeydelivers/riscv_security_contest_toolchain).

A copy of our application is available [here](doc/application.md)

**The content of the repository is frozen**. Only cosmetic changes to the
documention/readme files are expected
(unless contest organizers allow us to do otherwise). Occasional fixes to the
testing infrastructure are also expected.

# Participants

- Alexey Baturo
- Anatoly Parshintsev
- Fedor Veselovsky
- Igor Chervatyuk
- Sergey Matveev

## Special thanks to:
- Arnaud Samama from Thales Group
- ARM corporation
- Kurapov Petr
- [maikmerten](https://github.com/maikmerten/spu32)
- Petushkov Igor

# License

**MIT**.
Unless some used open-source component prevents that. We are not lawyers.


# Bulding the project

Build the toolchain:
1. `git clone --recursive https://github.com/spacemonkeydelivers/riscv_security_contest_toolchain`
1. `cd riscv_security_contest_toolchain`
1. `./configure --prefix=<RISCV_TOOLCHAIN_PATH> -with-arch=rv32imc --with-abi=ilp32`
1. `make newlib -j10`

Build RTL simulator (verilator) and run tests:
1. `git clone --recursive https://github.com/spacemonkeydelivers/riscv_security_contest_project`
1. `cd riscv_security_contest_project`
1. `cd zephyrproject`
1. `run pip3 install --user west`
1. `west init -l zephyr/`
1. `west update`
1. `pip3 install -r zephyr/scripts/requirements.txt`
1. `cd ../ && mkdir build && cd build`
1. `RISCV_TOOLCHAIN=<RISCV_TOOLCHAIN_PATH> cmake  ../ && make -j10`
1. Running all the existing tests with: `ctest -j10`

# Testing infrastructure

Our testing infrastructure is rather sophisticated and allows a wide range of
testing scenarios. The primary focus was to make the simulation of an
assembly-based or c-based program as simple (for the user) as possible.
**At the moment of our submission, it was still at the stage of active
development**.

We use cmake to create "test list files" and ctest to run our tests. The
execution of each test is driven by a python script. This python script
contains an embedded debugger and facilities to dump .vcd and trace files.

To know which commands are executed during test run one may pass `-V` option
to **ctest** program.

## Examples:

To run test use the following command:
```
ctest -R "expr_to_match_test_name"
```

If you want to run with **tracing** enable, use the following command:
```
 DBG="+trace" ctest -R malloc -V
```

## Running Zephyr-based programs

By default, when the project is built, our build scripts build several
zephyr-based programs, namely these ones:

- **zephyr_ripe[1-5]**
- **zephyr_philosophers**
- **zephyr_hello_world**
- **zephyr_mte_demo**
- and some others

**zephyr_ripe[1-5]** are pre-built images of the attacks which we should
mitigate.  Our design demonstrates mitigation for tests **zephyr_ripe1** and
**zephyr_ripe5**.

The purpose of **zepyhyr_mte_demo** is to demonstrate how
**SecureMonitorPanic** interrupt works in cases when our HW detect an
out-of-bounds access.

**zephyr_philosophers** demonstrates that other zephyr subsystems work as
expected with our design. To see dynamic output (from uart) one should do:
`cd $BUILD_DIR ; tail -f tests/zephyr_philosophers/io.txt` - this way you can
see what is printed to the uart port as the simulation goes on.

Please do note, that for tests that depend on the timer functionality the
simulation process is quite slow.  For example, one may have to wait about
**4 minutes** for an `eating philosopher` to become a `thinking philosopher`.

**Important note:** for zephyr-based tests "test exit code" , reported by `ctest`
does not indicate the actual pass/fail status of the test. To figure out how
test terminates, one has to check `io.txt` file of the test. **io.txt** file
is located at:

```
$BUILD_DIR/tests/<test_name>/io.txt
```

Alternatively the user can run `ctest` with `-V` option, like this:

```
ctest -R zephyr_ripe1 -V
```

Then, the contents of `io.txt* shall be printed to standard output once
simulation is complete.

# Risc-V core

HDL files describing our design are located in [rtl](rtl/) folder.

- Instruction set: **rv32imc**-compliant + custom [memtag extension](doc/arch/memtag.md).
- Peripheral: riscv-compliant timer, uart (transmit part only).

To speedup core development we used [cpu32 core](https://github.com/maikmerten/spu32)
and extended it to be IMC compatible.

## SOC memory map

Memory map for this particular SoC is located in 32 bit address space and consists of:

```
- 0x00000000 : 0x3FFFFFFF - RAM address space. It's wrapped with RAM size.
- 0x40000000 : 0x7FFFFFFF - Timer address space
- 0x80000000 : 0xBFFFFFFF - Uart address space
- 0xC0000000 : 0xFFFFFFFF - nothing mapped here yet
```

### Timer details

- **mtime** is at `0x40000000`
- **mtimecmp** is at `0x40000008`

SOC-specific control for timer frequency:

- **BEEHIVE_MTIMECTRL** is at `0x40000010`

TODO: add details.

### UART details

- **UART_BAUD_DIVIDER** is at `0x80000000`
- **UART_TX** is at `0x80000004`

# Used open source components

| name       | purpose  | git | license |
| ----       | -------  | --- | ------- |
| Tiny printf | libc: printf implementation | [github](https://github.com/mpaland/printf) | MIT |
| __moddi3/__divdi3 | libc: sw division from libgcc | [github mirror](https://github.com/gcc-mirror/gcc/tree/master/libgcc) | GPL2+ |
| __mulsi3 | libc: sw multiplication | [github mirror](https://github.com/gcc-mirror/gcc/blob/master/libgcc/config/epiphany/mulsi3.c) | GPL2+ |
| TODO | TODO | TODO |


