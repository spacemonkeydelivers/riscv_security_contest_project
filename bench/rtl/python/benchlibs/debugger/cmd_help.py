
class CmdHelp:
    def __init__(self, benchlib, soc, debugger):
        self._soc = soc
        self._bench = benchlib

    def names(self):
        return ['help']

    def help(self):
        self.run([])

    def run(self, args):
        print("\n".join(['',
           'we have the following command supported:',
           '    - print',
           '    - step',
           '    - tick',
           '    - e[X|x]amine',
           '    - go',
           '    - help',
           'Please run `<cmd_name> help` for the usage details'
           ]))
        return None


