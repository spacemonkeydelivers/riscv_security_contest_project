# Overview

This repository is a publically-available copy of a work performed by a team
of SW engineers in an attempt to participate in
[RISCV security contest](https://riscv.org/2019/07/risc-v-softcpu-core-contest).


This repository contains:

1. HDL design (verilog) of an IMC-compliant RISC-V core integrated in a
custom SOC. The soc is called "beehive-riscv!".
1. Our design introduces new extension to support HW memory tagging. The design
of an extension is documented [here](doc/arch/memtag.md).
1. Testing infrastructure and libraries used to test the design. This includes
scripts to enable simulation (verilator) and emulation (an fpga by xilinx).
1. Design documents used for development.
1. A copy of zephyr OS for RISV platform with a set of custom patches enhancing
(at least we hope so) security.
1. The project also requires GNU toolchain with a set of custom patches. It is
available from this
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

## Special thanks:
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

# Risc-V core

HDL files describing our design are located in [rtl](rtl/) folder.

- Instruction set: **IMC** compliant + custom [memtag extension](doc/arch/memtag.md).
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

- **UART_TX** is at `0x80000004`

**TODO:** add details about the configuration interface.


# Used open source components

| name       | purpose  | git | license |
| ----       | -------  | --- | ------- |
| Tiny printf | libc: printf implementation | [github](https://github.com/mpaland/printf) | MIT |
| __moddi3/__divdi3 | libc: sw division from libgcc | [github mirror](https://github.com/gcc-mirror/gcc/tree/master/libgcc) | GPL2+ |
| __mulsi3 | libc: sw multiplication | [github mirror](https://github.com/gcc-mirror/gcc/blob/master/libgcc/config/epiphany/mulsi3.c) | GPL2+ |
| TODO | TODO | TODO |


