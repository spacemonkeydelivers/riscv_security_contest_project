
class CmdHelp:
    def __init__(self, benchlib, soc, debugger):
        self.soc = soc
        self.bench = benchlib
        self.debugger = debugger

    def names(self):
        return ['help']

    def help(self):
        self.run([])

    def run(self, args):
        print("\n".join(['',
           'we have the following command supported:',
           ' - ' + "\n - ".join(self.debugger._cmd.keys()),
           'Please run `<cmd_name> help` for the usage details'
           ]))
        return None


