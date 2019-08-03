import sys
import os
import subprocess

import benchlibs.soc as soc_lib

def build_test_image():
  asm_file = os.environ['TESTS_DIR'] + '/asm/' + sys.argv[2]
  tools_dir = os.environ['TOOLS_DIR']
  cmd = '(echo \'<% input_asm="{}"; bench="{}" %>\' && cat \'{}\') | erb > Makefile'.format(
        asm_file, tools_dir, tools_dir + '/Makefile.erb')

  print('running <{}>'.format(cmd))
  sys.stdout.flush()
  ret = os.system(cmd)
  if ret != 0:
    raise 'could not generate makefile'
  sys.stdout.flush()

  print('running make...')
  sys.stdout.flush()
  ret = os.system('make VERBOSE=1')
  if ret != 0:
    raise 'could not create test image'
  sys.stdout.flush()

def run(libbench):

  build_test_image()

  soc = soc_lib.RiscVSoc(libbench, 'memtest_trace.vcd', True)
  # prepare execution environment
  # Issue is with sb instruction, 
  soc.print_ram(0x100 / 4, 1)
  # TODO: re-implement this function. add error reporting (exception)
  soc.load_data_to_ram("test.v")
  soc.tick(100)
  # expected value at 0x100 address after the sequence is 0x55555555
  # real value at 0x100 address is 0x00000055
  soc.print_ram(0x100 / 4, 1)

