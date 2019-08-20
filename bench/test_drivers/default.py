import sys
import os
import subprocess
import glob
import imp
import re

import benchlibs.soc as soc_lib
import benchlibs.debug as debug

PATH_tools_dir = os.environ['TOOLS_DIR']

def generate_make_compliance(soc):

  asm_file = os.environ['TESTS_DIR'] + '/' + sys.argv[1]
  cmd = '(echo \'<% input_asm="{}" %>\' && cat \'{}\') | erb > Makefile.test'.format(
          asm_file, PATH_tools_dir + '/misc/Makefile_compliance.erb')

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

  asm_file = os.environ['TESTS_DIR'] + '/' + sys.argv[1]
  cmd = '(echo \'<% input_asm="{}";  %>\' && cat \'{}\') | erb > Makefile.test'.format(
        asm_file, PATH_tools_dir + '/misc/Makefile_asm.erb')

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

  c_root = os.path.join(os.environ['TESTS_DIR'], sys.argv[1])
  pattern = os.path.join(c_root, '*.c')
  print('searching for c files as <{}>'.format(pattern))
  c_list = ' '.join(glob.glob(pattern))
  print('found results: {}'.format(c_list))

  cmd = ''.join([
          '(echo \'<% input_c="{}"; %>\' && cat \'{}\') ',
          '| erb > Makefile.test'
        ]).format(c_list, PATH_tools_dir + '/misc/Makefile_c.erb')

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
  test_type = sys.argv[1].split("/")[0]

  if test_type == "c":
    driver = generate_make_c(soc)
  elif test_type == "asm":
    driver = generate_make_asm(soc)
  elif test_type == "compliance":
    driver = generate_make_compliance(soc)
  elif test_type == "debugger":
    driver = generate_make_asm(soc)
  else:
    raise Exception("unknown test type {}".format(test_type))

  print('running make...')
  ret = os.system('make -f Makefile.test VERBOSE=1')
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
    enforce_repl = False
    for arg in sys.argv:
        m = re.search('--driver_arg=(.*)', arg)
        if m:
            found = m.group(1)
            if found == "--expect-failure":
                expect_failure = True
            if found == '--repl':
                enforce_repl = True

    dbg = debug.Debugger(libbench, soc)
    ticks = soc.get_ticks_to_run()
    if sys.stdout.isatty() or enforce_repl:
      print('TTY session detected! starting debugger')
      dbg.set_tracing_enabled(True)
      dbg.repl()
    else:
      soc.run(ticks, expect_failure = expect_failure)
  else:
    print "custom driver detected, control transfered"
    driver.run(soc)

