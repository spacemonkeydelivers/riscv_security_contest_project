
class CmdAssign:
    def __init__(self, benchlib, soc, debugger):
        self._soc = soc
        self._bench = benchlib

    def names(self):
        return ['NOT IMPLEMENTED: assign']

    def help(self):
        print("\n".join(['"assign" command. NOT IMPLEMENTED.',
          'Synopsis: assign variable value',
          'NOT IMPLEMENTED. This command assigns the specified value to a variable'
          ]))

    def run(self, args):
        print('Error: incorrect <assign> command. Command is unsupported yet.')
        return None

