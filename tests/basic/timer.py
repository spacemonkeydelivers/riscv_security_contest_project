import sys
import os

import benchlibs.soc as soc_lib

def run(libbench):
  soc = soc_lib.RiscVSoc(libbench, 'memtest_trace.vcd', True)
  # Issue is with sb instruction, 
  soc.print_ram(0x100 / 4, 1)
  soc.load_data_to_ram("/tmp/timer.hex")
  soc.tick(50)
  # expected value at 0x100 address after the sequence is 0x55555555
  # real value at 0x100 address is 0x00000055
  soc.print_ram(0x100 / 4, 1)

