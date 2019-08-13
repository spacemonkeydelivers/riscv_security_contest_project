import sys
import os
import subprocess
import glob
import imp
import re

import benchlibs.soc as soc_lib

def generate_make_compliance(soc):

  asm_file = os.environ['TESTS_DIR'] + '/' + sys.argv[2]
  include_dir = os.environ['TESTS_DIR'] + '/compliance/include/'
  tools_dir = os.environ['TOOLS_DIR']
  cmd = '(echo \'<% input_asm="{}"; bench="{}"; includes="{}" %>\' && cat \'{}\') | erb > Makefile'.format(
        asm_file, tools_dir, include_dir, tools_dir + '/misc/Makefile_compliance.erb')

  print('running <{}>'.format(cmd))
  ret = os.system(cmd)
  if ret != 0:
    raise 'could not generate makefile'

  driver = None
  # try to detect custom driver fot this test
  driver_path = asm_file + ".py"
  if os.path.isfile(driver_path):
    driver = imp.load_source("custom_driver", driver_path)
  return driver

def generate_make_asm(soc):

  asm_file = os.environ['TESTS_DIR'] + '/' + sys.argv[2]
  tools_dir = os.environ['TOOLS_DIR']
  cmd = '(echo \'<% input_asm="{}"; bench="{}" %>\' && cat \'{}\') | erb > Makefile'.format(
        asm_file, tools_dir, tools_dir + '/misc/Makefile_asm.erb')

  print('running <{}>'.format(cmd))
  ret = os.system(cmd)
  if ret != 0:
    raise 'could not generate makefile'

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

  cmd = ''.join([
          '(echo \'<% input_c="{}"; tools_distrib="{}"; ram_size={} %>\' && cat \'{}\') ',
          '| erb > Makefile'
        ]).format(
        c_list, tools_distr, ram_size, tools_dir + '/misc/Makefile_c.erb')
  print('running <{}>'.format(cmd))
  ret = os.system(cmd)
  if ret != 0:
    raise 'could not generate makefile'

  driver = None
  driver_path = os.path.join(c_root, "driver.py")
  if os.path.isfile(driver_path):
    driver = imp.load_source("custom_driver", driver_path)
  return driver

def build_test_image(soc):
  test_type = sys.argv[2].split("/")[0]

  if test_type == "c":
    driver = generate_make_c(soc)
  elif test_type == "asm":
    driver = generate_make_asm(soc)
  elif test_type == "compliance":
    driver = generate_make_compliance(soc)
  else:
    pass

  print('running make...')
  ret = os.system('make VERBOSE=1')
  if ret != 0:
    raise 'could not create test image'

  return driver



def run(libbench):

  soc = soc_lib.RiscVSoc(libbench, 'memtest_trace.vcd', True)

  driver = build_test_image(soc)

  soc.setDebug(False)
  soc.load_data_to_ram("test.v")

  if driver == None:
    print "could not detect custom driver, using standard procedure"

    expect_failure = False
    for arg in sys.argv:
        m = re.search('--driver_arg=(.*)', arg)
        if m:
            found = m.group(1)
            if found == "--expect-failure":
                expect_failure = True

    # prepare execution environment
    # BUG: Issue is with sb instruction, 
    # TODO: re-implement this function. add error reporting (exception)
    #soc.register_tick_callback(soc.print_pc)
    soc.go(10 ** 5, expect_failure = expect_failure)
  else:
    print "custom driver detected, control transfered"
    driver.run(soc)

