import sys
import os
import subprocess
import glob
import imp
import re

import dut_wrapper.soc as soc_lib
import benchlibs.debug as debug

from benchlibs.image_loader import ImageLoader

from builders.builder_asm import BuilderAsm
from builders.builder_c import BuilderC
from builders.builder_compliance import BuilderCompliance
from builders.builder_zephyr import BuilderZephyr

import subprocess, os, sys

def build_test_image(soc):

  test_type = sys.argv[1].split("/")[0]

  if test_type == "c":
    builder = BuilderC(soc)
  elif test_type == "asm":
    builder = BuilderAsm(soc)
  elif test_type == "compliance":
    builder = BuilderCompliance(soc)
  elif test_type == "zephyr":
    builder = BuilderZephyr(soc)
  elif test_type == "debugger":
    builder = BuilderAsm(soc)
  else:
    raise Exception("unknown test type {}".format(test_type))

  return builder.find_driver()

def run(libbench):
  soc = soc_lib.RiscVSoc(libbench, 'memtest_trace.vcd', True)

  driver = build_test_image(soc)

  soc.setDebug(False)
  ImageLoader.load_image("test.v", soc)
  soc.load_data_to_ram("test.v", external = False)

  if driver == None:
    print "could not detect custom driver, using standard procedure"

    expect_failure = False
    enforce_repl = False

    for arg in sys.argv:
      if arg == '--driver-invert-result':
        expect_failure = True
      if arg == '--repl':
        enforce_repl = True

    dbg = debug.Debugger(libbench, soc)
    ticks = soc.get_ticks_to_run()
    if sys.stdout.isatty() or enforce_repl:
      print('TTY session detected! starting debugger')

      # Unbuffer output (this ensures the output is in the correct order)
      sys.stdout = os.fdopen(sys.stdout.fileno(), 'w', 0)

      tee = subprocess.Popen(["tee", "log.txt"], stdin=subprocess.PIPE)
      os.dup2(tee.stdin.fileno(), sys.stdout.fileno())
      os.dup2(tee.stdin.fileno(), sys.stderr.fileno())

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
    driver.run(libbench, soc)

