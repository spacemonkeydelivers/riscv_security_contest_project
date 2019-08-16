class CmdTick:
    def __init__(self, benchlib, soc, debugger):
        self._soc = soc
        self._bench = benchlib

    def names(self):
        return ['tick']

    def help(self):
        print("\n".join(['"tick" command',
          'Synopsis: tick [TODO]',
          ]))

    def run(self, args):
        print('Tick::run')
        print('Error: incorrect <tick> command')
        return None




