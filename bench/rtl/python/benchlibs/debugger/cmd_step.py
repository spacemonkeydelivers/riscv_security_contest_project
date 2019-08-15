class CmdStep:
    def __init__(self, benchlib, soc, debugger):
        self._soc = soc
        self._bench = benchlib

    def names(self):
        return ['step']

    def help(self):
        print("\n".join(['"step" command.',
          'Synopsys: step [num]'
          ]))

    def run(self, args):
        print('Step::run')
        return None


