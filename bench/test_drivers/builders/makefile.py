import sys
import imp
import os
import re

PATH_tools_dir = os.environ['TOOLS_DIR']

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
    print('detacted data to build uart checker')
    with open('uart.expected', 'w') as f:
      for item in checker_data:
        f.write(item)
  else:
    print('no data to build uart checker available')
    if os.path.isfile('uart.expected'):
      os.remove('uart.expected')


class MakeFileBuilder:
  def __init__(self, erb_data, erb_template, custom_driver_path):
    cmd = '(echo \'{}\' && cat \'{}\') | erb > Makefile.test'.format(
        erb_data, '/'.join([os.environ['TOOLS_DIR'], '/misc/',erb_template]))

    print('running <{}>'.format(cmd))
    ret = os.system(cmd)
    if ret != 0:
      raise Exception('could not generate makefile')

    make_cmd = 'make -f Makefile.test VERBOSE=1'
    print('running {}...'.format(make_cmd))
    ret = os.system(make_cmd)
    if ret != 0:
      raise Exception('could not create test image')
    print('... done')

    self.driver = None

    print('searching for custom driver @{}'.format(custom_driver_path))
    if (custom_driver_path != None) and (os.path.isfile(custom_driver_path)):
      print('... custom driver found, loading')
      self.driver = imp.load_source("custom_driver", custom_driver_path)
    else:
      print('... none found')

  def build_uart_checker(self, files):
    for f in files:
      extract_uart_checker(f)

  def find_driver(self):
    self.driver

