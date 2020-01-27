import sys
import os
import subprocess
import glob
import imp
import re

import dut_wrapper.soc as soc_lib
import benchlibs.debug as debug
import runner_checks as rchecks

from chores.teelog import TeeLog
from benchlibs.image_loader import ImageLoader

def run(libbench, opts, runner_override = None):

  soc = soc_lib.RiscVSoc(libbench, 'memtest_trace.vcd', True)
  soc.setDebug(False)
  soc.setResetPC()

  ImageLoader.load_image("test.v", soc)

  if runner_override:
    print "custom runner procedure detected, control transfered"
    return driver.run(libbench, soc)

  print "could not detect custom runner procedure, using standard procedure"

  objdump_bin = os.environ['TOOLCHAIN_DIR'] + '/bin/riscv32-unknown-elf-objdump'
  dbg = debug.Debugger(libbench, soc, objdump_bin)

  if opts.ticks_limit == 0:
    print 'no ticks_limit specified, getting limit from the SOC object'
    opts.ticks_limit = soc.get_ticks_to_run()
    print 'new ticks_limit: {}'.format(opts.ticks_limit)

  if sys.stdout.isatty() or opts.enforce_repl:
    print('TTY session detected! starting debugger')

    # Unbuffer output (this ensures the output is in the correct order)
    sys.stdout = os.fdopen(sys.stdout.fileno(), 'w', 0)

    if sys.stdin.isatty():
      tee = TeeLog("log.txt", "w")
      dbg.set_tracing_enabled(True)
      dbg.repl()
    else:
      print("stdin is not TTY reading data directly...")
      for line in sys.stdin:
        print('>>>: `' + line.rstrip() + '`')
        dbg.process_input(line)
  else:
    soc.run(opts.ticks_limit, expect_failure = opts.expect_failure)
    print("Working directory: {}".format(os.getcwd()))
    rchecks.RunnerChecks().check_uart('io.txt')

