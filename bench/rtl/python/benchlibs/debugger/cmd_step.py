class CmdStep:
    def __init__(self, benchlib, soc, debugger):
        self.soc = soc
        self.bench = benchlib
        self.debugger = debugger

        self.prev_state = None

    def names(self):
        return ['step']

    def help(self):
        print("\n".join(['"step" command.',
          'Synopsys: step [num]',
          'This command executes the specified number of instructions'
          ]))

    def stepi(self):
        run = True
        while run:
            prev_state = self.soc._soc.cpuState()
            self.soc.tick()
            new_state = self.soc._soc.cpuState()

            if (prev_state != new_state) and (new_state == self.bench.en_state.FETCH):
                run = False

    def run(self, args):
        if len(args) == 0:
          args = [1]

        if len(args) == 1:
            num_str = args[0]
            try:
                num = int(num_str)
                for i in range(0, num):
                    self.stepi()
                upc = self.soc.upc()
                next_insn = self.debugger._disasm.display(upc)
                print('next: {0}'.format(next_insn))
            except ValueError:
                print 'Error: could not figure out how many steps required'
            return

        print('Error: incorrect <step> command')
        return None


