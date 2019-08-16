
class CmdAssign:
    def __init__(self, benchlib, soc, debugger):
        self._soc = soc
        self._bench = benchlib

    def names(self):
        return ['assign - TODO']

    def help(self):
        print("\n".join(['"assign" command',
          'Synopsis: assign variable value',
          'This command assigns the specified value to a variable'
          ]))

    def run(self, args):
        print('Error: incorrect <assign> command. Command is unsupported yet.')
        return None

