#TODO: logger instead of prints?
import sys
import os

sys.path.append(LIB_FILES)
import soc

soc = soc.RiscVSoc(libbench, 'memtest_trace.vcd', True)
soc.load_data_to_ram("/tmp/rv_mem.txt")
soc.print_ram()
soc.tick(100)
soc.print_register_file()
print(hex(soc.pc()))
