from __future__ import unicode_literals

import benchlibs.debugger.disasm as disasm_lib
from collections import OrderedDict
import os

from prompt_toolkit import prompt
from prompt_toolkit.history import FileHistory
from prompt_toolkit.auto_suggest import AutoSuggestFromHistory

from debugger.cmd_examine import CmdExamine
from debugger.cmd_go import CmdGo
from debugger.cmd_help import CmdHelp
from debugger.cmd_print import CmdPrint
from debugger.cmd_step import CmdStep
from debugger.cmd_tick import CmdTick

class Debugger:
    def register_cmd(cmd):
        return None

    def __init__(self, benchlib, soc):
        self._disasm = disasm_lib.Disassembler(None)
        self._bench  = benchlib
        self._soc    = soc
        self._cmd    = {}

        commands = [
            CmdExamine,
            CmdGo,
            CmdHelp,
            CmdPrint,
            CmdStep,
            CmdTick
        ]
        [self.add_command(cmd) for cmd in commands]

        self._trace = {
            'state': None,
            'states': OrderedDict(),
            'tick_cnt': 0
        }
        if os.environ.has_key('DBG'):
            DBG = [x.strip() for x in os.environ['DBG'].split(' ')]
        else:
            DBG = ''

        if '+trace' in DBG:
            self.set_tracing_enabled(True)

    def add_command(self, command):
        handler = command(self._bench, self._soc, self)
        for name in handler.names():
            if self._cmd.has_key(name):
                raise Exception('command duplication detected')
            self._cmd[name] = handler
        return None

    def set_tracing_enabled(self, value):
        if value:
            self._soc.register_tick_callback(self.tracing_callback)
        else:
            self._soc.unregister_tick_callback(self.tracing_callback)

    def tracing_callback(self):

        self._trace['tick_cnt'] += 1
        new_state = self._soc._soc.cpuState()
        if new_state == self._bench.en_state.FETCH:
            if (self._trace['state'] != new_state):
                s = []

                for k in self._trace['states']:
                    v = self._trace['states'][k]
                    s.append('{}({})'.format(k, v))
                print('     - {} || tick#{}'.format(','.join(s), self._trace['tick_cnt']))

                self._trace['states'].clear()
                pc = self._soc.pc()
                msg = self._disasm.display(pc)
                print(msg)

        self._trace['state'] = new_state
        if self._trace['states'].has_key(str(new_state)):
           self._trace['states'][str(new_state)] += 1
        else:
           self._trace['states'][str(new_state)] = 1

    def stepi(self, n):
        return None

    def repl(self):
        while True:
            try:
                user_input = prompt('>',
                    history=FileHistory('.history.txt'),
                    auto_suggest=AutoSuggestFromHistory(),
                )
            except EOFError:
                break

            input_cmd = [x.strip() for x in user_input.split()]
            input_cmd = [i for i in input_cmd if i] 

            if len(input_cmd) == 0:
                continue

            cmd = input_cmd[0]
            input_cmd.pop(0)

            if self._cmd.has_key(cmd):
                if len(input_cmd) > 0:
                  if input_cmd[0] == 'help':
                        self._cmd[cmd].help()
                        continue
                self._cmd[cmd].run(input_cmd)
            else:
                print("Error: unknown command {}".format(cmd))

