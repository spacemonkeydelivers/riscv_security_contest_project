from collections import OrderedDict

REG_NAMES = {
  0: 'x0',
  1: 'ra',  2: 'sp',  3: 'gp',  4: 'tp',
  5: 't0',  6: 't1',  7: 't2',
  8: 's0',  9: 's1',
  10: 'a0', 11: 'a1',
  12: 'a2', 13: 'a3', 14: 'a4', 15: 'a5', 16: 'a6', 17: 'a7',
  18: 's2', 19: 's3', 20: 's4', 21: 's5', 22: 's6', 23: 's7',
  24: 's8', 25: 's9', 26: 's10', 27: 's11',
  28: 't3', 29: 't4', 30: 't5',  31: 't6'
}

class CmdPrint:
    def __init__(self, benchlib, soc, debugger):
        self.soc = soc
        self.bench = benchlib
        self.debugger = debugger

    def names(self):
        return ['print', 'p']

    def help(self):
        print("\n".join(['"print" command.',
          'Synopsys: print [regs|cpu.state|pc|<reg_name>]'
          ]))

    def print_reg_row(self, r):
        s = []
        for i in r:
          reg_value = self.soc.read_register(i)
          s.append('    {0:3}: {1:#010x}'.format(REG_NAMES[i], reg_value))

        print(' '.join(s))

    def print_regs(self):
        print '--- Register file: ---'
        cols = 4
        for i in range(0, 32 / cols):
          self.print_reg_row(range(i * cols, i * cols + cols))
        print '______________________'

    def print_state(self):

        tick_ctr = self.debugger._soc._soc.counterGetTick()
        step_ctr = self.debugger._soc._soc.counterGetStep()

        pc = self.soc.pc()
        upc = self.soc.upc()
        print '--- CPU state ---'
        print 'step: #{}, utick: {}'.format(step_ctr, tick_ctr)
        disasm = self.debugger._disasm.display(pc, self.soc)
        udisasm = self.debugger._disasm.display(upc, self.soc)
        if disasm != udisasm:
            print 'stale pc: {}'.format(disasm)
            print 'unstable pc: {}'.format(udisasm)
        else:
            print disasm
            print 'pc is stable'
        state = self.soc._soc.cpuState()
        print 'state: {}'.format(state)
        self.debugger.print_utrace()
        print '_________________'

    def run(self, args):
        if len(args) == 0:
            args = ["cpu.state"]

        if args[0] == "pc":
            args = ["cpu.state"]

        if args[0] == "regs":
            self.print_regs()
            return None
        if args[0] == "cpu.state":
            self.print_state()
            return None

        if args[0] in REG_NAMES.values():
            for number, name in REG_NAMES.items():
                  if name == args[0]:
                      reg_value = self.soc.read_register(number)
                      print('    {0:3}:  {1:#010x}'.format(name, reg_value))
                      return None

        print('Error: incorrect <print> command')
        return None

