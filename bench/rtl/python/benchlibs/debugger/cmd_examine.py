
class CmdExamine:
    def __init__(self, benchlib, soc, debugger):
        self._soc = soc
        self._bench = benchlib

    def names(self):
        return ['examine', 'x']

    def help(self):
        self.run([])

    def run(self, args):
        print("\n".join(['"examine" command',
          'Synopsis: {examine|x} [TODO]',
          ]))
        return None

