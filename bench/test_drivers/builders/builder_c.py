from makefile import MakeFileBuilder
import glob
import sys
import re
import os

def extract_c_directives(filename, directives):

  directives.append('disable_security = false')
  directives.append('disable_warnings = false')

  for arg in sys.argv:
    if arg == '--nonsecure-libc':
        directives.append('disable_security = true')
    if arg == '--disable-c-warnings':
        directives.append('disable_warnings = true')

def make_command_line():
  cmd_file = None
  for arg in sys.argv:
      m = re.search('--cmd="(.*?)"', arg)
      if m:
        cmd_file = m.group(1)
      elif arg.startswith('--cmd='):
        cmd_file = arg[6:]

  content = ["test.elf"]

  if cmd_file != None:
    if cmd_file.startswith('./'):
      the_file = os.path.join(os.environ['TESTS_DIR'], sys.argv[1], cmd_file[2:])
    elif not cmd_file.startswith('/'):
      the_file = os.path.join(os.environ['TESTS_DIR'], cmd_file)
    else:
      the_file = cmd_file

    print('reading command line from file <{}> [{}]'.format(the_file, cmd_file))
    with open(the_file) as f:
      input_lines = f.read().splitlines()
      # detect comments, if any
      comments = []
      scan_for_comments = input_lines[0][0] == '#'
      for line in input_lines:
        if scan_for_comments:
          if line == '':
            scan_for_comments = False
          else:
            if line[0] == '#':
              comments.append(line)
            else:
              raise Exception('comments in config file must start with `#`')
        else:
          content.append(line)

      print('- Extracted comments:')
      if len(comments) > 0:
        print('\n'.join(comments))
      else:
        print('-')
      print('- Extracted line:')
      print("'" + '\' \''.join(content) + "'")
  else:
    print('extern command line is not detected, generating the default one')

  args_n = len(content)

  asm = []
  asm.append('.global __ARGS_INFO')
  asm.append('.section ".__command_line", "awx"')
  asm.append('.balign 4; __ARGS_INFO:')
  asm.append('.4byte {}'.format(args_n))
  asm.extend(['.4byte ._arg_{}'.format(ind) for ind, x in enumerate(content)])
  asm.extend(['._arg_{}: .string "{}"'.format(ind, x) for ind, x in enumerate(content)])
  asm.append('');

  with open("command_line.s", "w") as f:
    f.write('\n'.join(asm))

class BuilderC(MakeFileBuilder):
  def __init__(self, soc):
    c_root = os.path.join(os.environ['TESTS_DIR'], sys.argv[1])
    pattern = os.path.join(c_root, '*.c')
    print('searching for c files as <{}>'.format(pattern))
    c_files = glob.glob(pattern)

    directives = []
    for c_file in c_files:
      # extract_uart_checker(c_file)
      extract_c_directives(c_file, directives)

    make_command_line()

    c_list = ' '.join(c_files)
    print('found results: {}'.format(c_list))
    erb_cmd = '<% input_c="{}"; c_root="{}"; {} %>'.format(
                  c_list, c_root, ';'.join(directives))

    MakeFileBuilder.__init__(self, erb_cmd, 'Makefile_c.erb', 'driver.py')

    self.build_uart_checker(c_files)

