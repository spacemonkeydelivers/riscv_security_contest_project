
class CmdGo:
    def __init__(self, benchlib, soc, debugger):
        self._soc = soc
        self._bench = benchlib

    def names(self):
        return ['go', 'csgo']

    def help(self):
        self.run([])

    def run(self, args):
        print("\n".join(['"go" command',
          'Synopsis: go [--|pc=addr]',
          'The command instructs environment to run simulation till the ',
          'specified condition is satisfied.',
          'Possible conditions:',
          '   <--> - run till "test exit"',
          '   <pc=addr> - run till current instruction pointer is equal to the addr'
          ]))
        return None



