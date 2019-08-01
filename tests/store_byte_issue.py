import sys
import os

sys.path.append(LIB_FILES)
import soc

soc = soc.RiscVSoc(libbench, 'memtest_trace.vcd', True)
# Issue is with sb instruction, 
soc.print_ram(0x100 / 4, 1)
# addi a0, zero, 0x55
soc.write_word_ram(0, 0x05500513)
# addi sp, zero 0x100
soc.write_word_ram(1, 0x10000113)
# sb a0, 0(sp)
soc.write_word_ram(2, 0x00a10023)
# sb a0, 1(sp)
soc.write_word_ram(3, 0x00a100a3)
# sb a0, 2(sp)
soc.write_word_ram(4, 0x00a10123)
# sb a0, 3(sp)
soc.write_word_ram(5, 0x00a101a3)
soc.tick(30)
# expected value at 0x100 address after the sequence is 0x55555555
# real value at 0x100 address is 0x00000055
soc.print_ram(0x100 / 4, 1)

