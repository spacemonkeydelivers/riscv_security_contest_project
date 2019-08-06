import sys
import os
import subprocess
import glob

import benchlibs.soc as soc_lib

def generate_make_asm():

  asm_file = os.environ['TESTS_DIR'] + '/asm/' + sys.argv[2]
  tools_dir = os.environ['TOOLS_DIR']
  cmd = '(echo \'<% input_asm="{}"; bench="{}" %>\' && cat \'{}\') | erb > Makefile'.format(
        asm_file, tools_dir, tools_dir + '/misc/Makefile_asm.erb')

  print('running <{}>'.format(cmd))
  sys.stdout.flush()
  ret = os.system(cmd)
  if ret != 0:
    raise 'could not generate makefile'
  sys.stdout.flush()

def generate_make_c():
  tools_dir = os.environ['TOOLS_DIR']
  tools_distr = os.environ['TOOLS_DISTRIB']
  c_root = os.path.join(os.environ['TESTS_DIR'], sys.argv[2])
  pattern = os.path.join(c_root, '*.c')
  print('searching for c files as <{}>'.format(pattern))
  c_list = ' '.join(glob.glob(pattern))
  print('found results: {}'.format(c_list))
  sys.stdout.flush()

  cmd = '(echo \'<% input_c="{}"; tools_distrib="{}" %>\' && cat \'{}\') | erb > Makefile'.format(
        c_list, tools_distr, tools_dir + '/misc/Makefile_c.erb')
  print('running <{}>'.format(cmd))
  sys.stdout.flush()
  ret = os.system(cmd)
  if ret != 0:
    raise 'could not generate makefile'
  sys.stdout.flush()

def build_test_image():

  if sys.argv[2].split("/")[0] == "c":
    generate_make_c()
  else:
    generate_make_asm()

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

