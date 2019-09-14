Hi folks,

First of all, please, let me thank you for organizing the contest.  We're a
small group of software engineers who have no relevant experience in hardware
field, but we'd love to get one. With this said we'd like to submit our attempt
for this contest.  Obviously, we didn't meet the contest requirements, since we
didn't have the exact FPGA board by Microsemi, instead we've been using
Starterkit board named
SK-AT91SAM9G45-XC6SLX(http://starterkit.ru/html/index.php?name=shop&op=view&id=50)
with Xilinx Spartan6 XC6SLX16. We've tested our design both on FPGA and
verilated simulation.  But we would really love to get the feedback from you
folks comparing our efforts with other contestants, but with no intents to have
any claims for prizes.

For most of us this was the largest HW project we've ever worked on :). As such
we believe that the schedule was a little bit too tight, for us - as we've spent
a significant amount of time debugging our SOC.

As our primary (and only :() HW mitigation techique we've implemeted HW memory
tagging (heavily inspired by ARM's MTE). Our implemention can protect
dynamic memory allocations. We do not have support for stack protection.

We've elaborated different techniques to mitigate the security issues:

- _implementing shadowstack_: this is a common technique, but the terms of the
contest forbid changing the zephyr sources, so we have to skip this one;
- _implementing hardware assisted CFI_: LLVM allows to use CFI to ensure
control flow integrity in a pure software way. Our idea was to extend this
approach and dump all possible targets of indirect jumps/returns and implement
& train Bloom's filter to check if a transition is valid;
- _implementing memory tagging_: another common technique, but it requires
changes in compiler to implement full support; Unfortunatelly in the given time
we could only implement memory tagging support for the dynamic allocations
(malloc). This allows us to mitigate several security issues related to heap
only with some extra hw support and adjusting libc implementation.

So, in order to bootstrap our project you'll need:
- build toolchain
- build the project
- run zephyr + ripe tests on verilator
- compile the design for Xilinx

Building the toolchain:  
1. git clone --recursive https://github.com/spacemonkeydelivers/riscv_security_contest_toolchain
1. cd riscv_security_contest_toolchain  
1. ./configure --prefix=<RISCV_TOOLCHAIN_PATH> -with-arch=rv32imc --with-abi=ilp32  
1. make newlib -j10  

Building the project:  
    1. git clone --recursive https://github.com/spacemonkeydelivers/riscv_security_contest_project
    2. cd riscv_security_contest_project  
    3. cd zephyrproject  
    4. run pip3 install --user west  
    5. west init -l zephyr/  
    6. west update  
    7. pip3 install -r zephyr/scripts/requirements.txt  
    8. cd ../ && mkdir build && cd build  
    9. RISCV_TOOLCHAIN=<RISCV_TOOLCHAIN_PATH> cmake  ../ && make -j10  
    10. Running all the existing tests with: ctest -j10   
        10.1. In order to run some tests by regexp, use -R: ctest -R asm_uart -j10  
        10.2. In order to see some more verbose output, use -V: ctest -R asm_uart -V -j10  
        10.3. In order to dump vcd trace, use environment variable DBG: DBG="+vcd" ctest -R asm_uart -V -j10  
        10.4. In order to dump instructions trace, use environment variable DBG: DBG="+vcd +trace" ctest -R asm_uart -V -j10  

Running zephyr+ripe tests:  
    1. ctest -R zephyr_ripe -j10 -V  
  
Compiling the design for fpga: 
    1. git clone --recursive https://github.com/spacemonkeydelivers/riscv_security_contest_project
    2. cd riscv_security_contest_project/fpga  
    3. edit project.cfg file and replace XILINX variable with a proper one  
    4. make  

Please find the resources consumption log for FPGA in attachment.
Thanks for the attention and waiting for your reply.

Best regards
