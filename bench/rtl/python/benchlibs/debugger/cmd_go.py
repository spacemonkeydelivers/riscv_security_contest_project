class CmdGo:
    def __init__(self, benchlib, soc, debugger):
        self.soc = soc
        self.bench = benchlib
        self.debugger = debugger

    def names(self):
        return ['go', 'csgo']

    def help(self):
        print("\n".join(['"go" command',
          'Synopsis: go [pc=addr]',
          'The command instructs environment to run simulation till the ',
          'specified condition is satisfied.',
          'Possible conditions:',
          '   <> - run till "test exit"',
          '   <pc=addr> - run till current instruction pointer is equal to the addr'
          ]))

    def run(self, args):

        arg_str = ("".join(args)).replace(" ", "").lower()

        if arg_str.startswith('pc='):
            tgt_pc_str = arg_str[3:]
            try:
                tgt_pc = int(tgt_pc_str, 0)
            except ValueError:
                print 'Error: could not figure out how many steps required'
                return None

            try:
                self.soc.run(10 ** 5, break_on = tgt_pc)
            except UserWarning:
                print('target PC={} reached: <{}>'.format(
                  tgt_pc_str, self.debugger._disasm.display(tgt_pc)))
            return None
        else:
            if len(args) == 0:
                ilimit = 10 ** 5
            else:
                try:
                    ilimit = int(args[0])
                except ValueError:
                    print 'Error: could not figure out how many steps required'
                    return None

            self.soc.run(ilimit)

        return None



