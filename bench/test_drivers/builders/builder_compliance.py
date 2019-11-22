from makefile import MakeFileBuilder
import sys
import os

class BuilderCompliance(MakeFileBuilder):
  def __init__(self):
    asm_file = os.environ['TESTS_DIR'] + '/' + sys.argv[1]
    cmd = '<% input_asm="{}"; %>'.format(asm_file)
    MakeFileBuilder.__init__(self, cmd, 'Makefile_compliance.erb', asm_file + '.py')

