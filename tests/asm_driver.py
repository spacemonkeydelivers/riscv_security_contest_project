import sys
import os
import subprocess
import glob
import imp

import benchlibs.soc as soc_lib

def generate_make_asm(soc):

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

  driver = None
  # try to detect custom driver fot this test
  driver_path = asm_file + ".py"
  if os.path.isfile(driver_path):
    driver = imp.load_source("custom_driver", driver_path)
  return driver

def generate_make_c(soc):
  ram_size = soc.get_soc_ram_size()

  tools_dir = os.environ['TOOLS_DIR']
  tools_distr = os.environ['TOOLS_DISTRIB']
  c_root = os.path.join(os.environ['TESTS_DIR'], sys.argv[2])
  pattern = os.path.join(c_root, '*.c')
  print('searching for c files as <{}>'.format(pattern))
  c_list = ' '.join(glob.glob(pattern))
  print('found results: {}'.format(c_list))
  sys.stdout.flush()

  cmd = ''.join([
          '(echo \'<% input_c="{}"; tools_distrib="{}"; ram_size={} %>\' && cat \'{}\') ',
          '| erb > Makefile'
        ]).format(
        c_list, tools_distr, ram_size, tools_dir + '/misc/Makefile_c.erb')
  print('running <{}>'.format(cmd))
  sys.stdout.flush()
  ret = os.system(cmd)
  if ret != 0:
    raise 'could not generate makefile'
  sys.stdout.flush()

  driver = None
  driver_path = os.path.join(c_root, "driver.py")
  if os.path.isfile(driver_path):
    driver = imp.load_source("custom_driver", driver_path)
  return driver

def build_test_image(soc):

  if sys.argv[2].split("/")[0] == "c":
    driver = generate_make_c(soc)
  else:
    driver = generate_make_asm(soc)

  print('running make...')
  sys.stdout.flush()
  ret = os.system('make VERBOSE=1')
  if ret != 0:
    raise 'could not create test image'
  sys.stdout.flush()

  return driver



def run(libbench):

  soc = soc_lib.RiscVSoc(libbench, 'memtest_trace.vcd', True)

  driver = build_test_image(soc)

  if driver == None:
    print "could not detect custom driver, using standard procedure"
    # prepare execution environment
    # Issue is with sb instruction, 
    soc.print_ram(0x100 / 4, 1)
    # TODO: re-implement this function. add error reporting (exception)
    soc.load_data_to_ram("test.v")
    soc.tick(100)
    # expected value at 0x100 address after the sequence is 0x55555555
    # real value at 0x100 address is 0x00000055
    soc.print_ram(0x100 / 4, 1)
  else:
    print "custom driver detect, control transfered"
    driver.run(soc)

