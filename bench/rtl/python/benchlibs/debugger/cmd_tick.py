class CmdTick:
    def __init__(self, benchlib, soc, debugger):
        self.soc = soc
        self.bench = benchlib
        self.debugger = debugger

    def names(self):
        return ['tick']

    def help(self):
        print("\n".join(['"tick" command',
          'Synopsis: tick [number]',
          'Simulate single "tick" (clk low->clk high transitions).',
          'May be useful for debugging of issues during execution of a single instruction.'
          ]))

    def run(self, args):
        if len(args) == 0:
            args = [1]

        if len(args) == 1:
            num_str = args[0]
            try:
                num = int(num_str)
                print('--- Tick Start ---')
                print('utrace before:')
                self.debugger.print_utrace()
                for i in range(0, num):
                    self.soc.tick()
                print('utrace after:')
                self.debugger.print_utrace()
                print('__________________')
                return 'tick {}'.format(num)
            except ValueError:
                print 'Error: could not figure out how many ticks required'
            return

        print('Error: incorrect <tick> command')
        return None




