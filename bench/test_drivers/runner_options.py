import os
import sys

class RunnerOptions():
  def __init__(self):

    self.ticks_limit = 0
    self.expect_failure = False
    self.spike_start_pc = 0
    self.enforce_repl = False

    self.dbg_enable_trace = False
    self.dbg_dump_vcd = False
    self.dbg_ticks_limit2 = 0

    for arg in sys.argv:
      if "--spike-start-pc" in arg:
        self.spike_start_pc = int(arg.split("=")[1])
      if arg == '--driver-invert-result':
        self.expect_failure = True
      if arg == '--repl':
        self.enforce_repl = True
      if "--ticks-timeout" in arg:
        self.ticks_limit = int(arg.split("=")[1])

    if os.environ.has_key('DBG'):
      DBG = [x.strip() for x in os.environ['DBG'].split(' ')]
    else:
      DBG = ''

    print('checking for os.environ("DBG") for [+trace, +vcd, +ticks_to_run]')

    if '+trace' in DBG:
      print 'env.DBG has +trace. Logging facilities enabled'
      self.dbg_enable_trace = True

    if '+vcd' in DBG:
      print 'env.DBG has +vcd. VCD dumping enabled'
      self.dbg_dump_vcd = True

    for arg in DBG:
      if '+ticks_to_run' in arg:
        self.dbg_ticks_limit2 = int(arg.split('=')[1])
        break

