from makefile import MakeFileBuilder
import sys
import os

class BuilderAsm(MakeFileBuilder):
  def __init__(self, soc):
    asm_file = os.environ['TESTS_DIR'] + '/' + sys.argv[1]
    cmd = '<% input_asm="{}"; %>'.format(asm_file)
    MakeFileBuilder.__init__(self, cmd, 'Makefile_asm.erb', asm_file + '.py')

    self.build_uart_checker([asm_file])

