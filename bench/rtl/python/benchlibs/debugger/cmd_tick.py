class CmdTick:
    def __init__(self, benchlib, soc, debugger):
        self._soc = soc
        self._bench = benchlib

    def names(self):
        return ['tick']

    def help(self):
        self.run([])

    def run(self, args):
        print("\n".join(['"tick" command',
          'Synopsis: tick [TODO]',
          ]))
        return None




