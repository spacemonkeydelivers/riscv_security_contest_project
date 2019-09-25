import dut_wrapper.soc as soc_lib

def run(libbench):
  soc = soc_lib.RiscVSoc(libbench, 'memtest_trace.vcd', True)
  # Issue is with sb instruction, 
  soc.print_ram(start_address = 0x100, num_words = 1)
  # addi a0, zero, 0x55
  soc.write_word_ram(0 * 4, 0x05500513)
  # addi sp, zero 0x100
  soc.write_word_ram(1 * 4, 0x10000113)
  # sb a0, 0(sp)
  soc.write_word_ram(2 * 4, 0x00a10023)
  # sb a0, 1(sp)
  soc.write_word_ram(3 * 4, 0x00a100a3)
  # sb a0, 2(sp)
  soc.write_word_ram(4 * 4, 0x00a10123)
  # sb a0, 3(sp)
  soc.write_word_ram(5 * 4, 0x00a101a3)
  for i in range(100):
    soc.tick()

  data = soc.read_word_ram(address = 0x100)
  # expected value at 0x100 address after the sequence is 0x55555555
  # real value at 0x100 address is 0x00000055
  expected = 0x55555555
  if (data != expected):
    msg = "got 0x{0:08x}, expected 0x{1:08x}".format(data, expected)
    raise Exception(msg)

