class CmdPrint:
    def __init__(self, benchlib, soc, debugger):
        self._soc = soc
        self._bench = benchlib

    def names(self):
        return ['print']

    def help(self):
        print("\n".join(['"print" command.',
          'Synopsys: print [regs|cpu.state|pc]'
          ]))

    def run(self, args):
        print('Print::run')
        return None

