import benchlibs.debug as debug

def run(libbench, soc):
  dbg = debug.Debugger(libbench, soc)
  dbg.set_tracing_enabled(True)
  dbg.stepi(5)
  # soc.run(5)
  dbg.process_input("p")
