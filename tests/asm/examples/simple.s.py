import benchlibs.debug as debug

def run(libbench, soc):
  dbg = debug.Debugger(libbench, soc)
  dbg.set_tracing_enabled(True)

  dbg.process_input("x /i4 0")

  dbg.stepi(4)
  dbg._soc.tick()

  dbg.process_input("p")
  print("")
  dbg.process_input("x /x4 0")
