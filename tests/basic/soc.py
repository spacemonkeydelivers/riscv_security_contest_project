import benchlibs.soc as soc_lib

def run(libbench):
  soc = soc_lib.RiscVSoc(libbench, 'memtest_trace.vcd', True)
  soc.load_data_to_ram("/tmp/rv_mem.txt")
  soc.print_ram()
  for i in range(0, 100):
    soc.tick()
  soc.print_register_file()
  print(hex(soc.pc()))
