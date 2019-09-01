from makefile import MakeFileBuilder
import sys
import os

class BuilderZephyr(MakeFileBuilder):
  def __init__(self, soc):
    test = sys.argv[1].split("/")[1]
    elf = os.path.join(os.environ['ZEPHYR_BUILDS'], test, 'zephyr', 'zephyr.elf')

    print('elf image: {}'.format(elf))
    erb_cmd = '<% elf="{}" %>'.format(elf)
    MakeFileBuilder.__init__(self, erb_cmd, 'Makefile_zephyr.erb', None)
