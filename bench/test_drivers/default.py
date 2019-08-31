import sys
import os
import subprocess
import glob
import imp
import re

import benchlibs.soc as soc_lib
import benchlibs.debug as debug

PATH_tools_dir = os.environ['TOOLS_DIR']

def extract_c_directives(filename, directives):
  with open(filename) as f:
    content = f.readlines()
    for line in content:
      if re.search(r'\s*SECURITY_CTRL:\s*DISABLE\s*', line):
        directives.append('disable_security = true')

def extract_uart_checker(filename):
  checker_data = []
  activated = False
  with open(filename) as f:
    content = f.readlines()
    for line in content:
      if re.search(r'^\s*UART_CHECK:ENABLED\s*$', line):
        activated = True
        continue

      if (activated == True) and re.search(r'^\s*\*/\s*$', line):
        activated = False
        if len(checker_data) > 0:
          checker_data[-1] = checker_data[-1][:-1]

      if activated:
        checker_data.append(line)

  if len(checker_data) > 0:
    with open('uart.expected', 'w') as f:
      for item in checker_data:
        f.write(item)
  else:
    if os.path.isfile('uart.expected'):
      os.remove('uart.expected')

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

  extract_uart_checker(asm_file)

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
  c_files = glob.glob(pattern)
  directives = ['disable_security = false']
  for c_file in c_files:
    extract_uart_checker(c_file)
    extract_c_directives(c_file, directives)


  c_list = ' '.join(c_files)
  print('found results: {}'.format(c_list))
  cmd = ''.join([
          '(echo \'<% input_c="{}"; {} %>\' && cat \'{}\') ',
          '| erb > Makefile.test'
        ]).format(c_list, ';'.join(directives), PATH_tools_dir + '/misc/Makefile_c.erb')

  print('running <{}>'.format(cmd))
  ret = os.system(cmd)
  if ret != 0:
    raise 'could not generate makefile'

  driver = None
  driver_path = os.path.join(c_root, "driver.py")
  if os.path.isfile(driver_path):
    driver = imp.load_source("custom_driver", driver_path)
  return driver

def generate_zephyr_image(soc):
  test = sys.argv[1].split("/")[1]
  elf = os.path.join(os.environ['ZEPHYR_BUILDS'], test, 'zephyr', 'zephyr.elf')
  print('elf image: {}'.format(elf))

  cmd = ''.join([
          '(echo \'<% elf="{}" %>\' && cat \'{}\') ',
          '| erb > Makefile.test'
        ]).format(elf, PATH_tools_dir + '/misc/Makefile_zephyr.erb')

  print('running <{}>'.format(cmd))
  ret = os.system(cmd)
  if ret != 0:
    raise 'could not generate makefile'

  return None


def build_test_image(soc):
  test_type = sys.argv[1].split("/")[0]

  if test_type == "c":
    driver = generate_make_c(soc)
  elif test_type == "asm":
    driver = generate_make_asm(soc)
  elif test_type == "compliance":
    driver = generate_make_compliance(soc)
  elif test_type == "zephyr":
    driver = generate_zephyr_image(soc)
  elif test_type == "debugger":
    driver = generate_make_asm(soc)
  else:
    raise Exception("unknown test type {}".format(test_type))

  print('running make...')
  ret = os.system('make -f Makefile.test VERBOSE=1')
  if ret != 0:
    raise Exception('could not create test image')

  return driver



def run(libbench):
  soc = soc_lib.RiscVSoc(libbench, 'memtest_trace.vcd', True)

  driver = build_test_image(soc)

  soc.setDebug(False)
  soc.load_data_to_ram("test.v", external = False)
  soc.enable_vcd_trace()

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
      if os.path.isfile('uart.expected'):
        ret = os.system(' && '.join(['cat io.txt | sed \'/^LIBC: /d\'>_io.txt',
                                     'diff _io.txt uart.expected']))
        if ret == 0:
          print('UART output matches the expected one')
        else:
          raise Exception('UART output mismatch!, test failed')
  else:
    print "custom driver detected, control transfered"
    driver.run(soc)

