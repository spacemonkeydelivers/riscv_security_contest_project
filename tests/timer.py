import sys
import os

sys.path.append(LIB_FILES)
import soc

soc = soc.RiscVSoc(libbench, 'memtest_trace.vcd', True)
# Issue is with sb instruction, 
soc.load_data_to_ram("/tmp/timer.hex")
soc.tick(100)

