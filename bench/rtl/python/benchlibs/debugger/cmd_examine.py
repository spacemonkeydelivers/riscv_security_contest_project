
class CmdExamine:
    def __init__(self, benchlib, soc, debugger):
        self._soc = soc
        self._bench = benchlib

    def names(self):
        return ['examine', 'x']

    def help(self):
        print("\n".join(['"examine" command',
          'Synopsis: {examine|x}[/format] addr',
          ]))

    def run(self, args):
        print('Examine::run')
        print('Error: incorrect <examine> command')
        return None

