from makefile import MakeFileBuilder
import glob
import sys
import re
import os

def extract_c_directives(filename, directives):
  with open(filename) as f:
    content = f.readlines()
    for line in content:
      if re.search(r'\s*SECURITY_CTRL:\s*DISABLE\s*', line):
        directives.append('disable_security = true')

class BuilderC(MakeFileBuilder):
  def __init__(self, soc):
    c_root = os.path.join(os.environ['TESTS_DIR'], sys.argv[1])
    pattern = os.path.join(c_root, '*.c')
    print('searching for c files as <{}>'.format(pattern))
    c_files = glob.glob(pattern)

    directives = ['disable_security = false']
    for c_file in c_files:
      # extract_uart_checker(c_file)
      extract_c_directives(c_file, directives)


    c_list = ' '.join(c_files)
    print('found results: {}'.format(c_list))
    erb_cmd = '<% input_c="{}"; c_root="{}"; {} %>'.format(
                  c_list, c_root, ';'.join(directives))

    MakeFileBuilder.__init__(self, erb_cmd, 'Makefile_c.erb', 'driver.py')

    self.build_uart_checker(c_files)

