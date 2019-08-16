
class CmdReset:
    def __init__(self, benchlib, soc, debugger):
        self._soc = soc
        self._bench = benchlib

    def names(self):
        return ['NOT IMPLEMENTED: reset']

    def help(self):
        print("\n".join(['"reset" command. NOT IMPLEMENTED',
          'Synopsis: reset',
          'NOT IMPLEMENTED. This command reloads memory image and resets CPU'
          ]))

    def run(self, args):
        print('Error: incorrect <reset> command. Command is unsupported yet.')
        return None

