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
from debugger.cmd_assign import CmdAssign
from debugger.cmd_reset import CmdReset
from debugger.cmd_watchpoint import CmdWatchpoint

class Debugger:
    def register_cmd(cmd):
        return None

    def __init__(self, benchlib, soc, objdump):
        self._disasm = disasm_lib.Disassembler(objdump)
        self._bench  = benchlib
        self._soc    = soc
        self._cmd    = {}
        self._rerun  = None

        commands = [
            CmdAssign,
            CmdReset,
            CmdExamine,
            CmdGo,
            CmdHelp,
            CmdPrint,
            CmdStep,
            CmdTick,
            CmdWatchpoint,
        ]
        [self.add_command(cmd) for cmd in commands]

        self._trace = {
            'state': None,
            'states': OrderedDict(),
            'tick_cnt': 0
        }

        # TODO: use runner_options.py code here
        if os.environ.has_key('DBG'):
            DBG = [x.strip() for x in os.environ['DBG'].split(' ')]
        else:
            DBG = ''

        if '+trace' in DBG:
            self.set_tracing_enabled(True)

        if '+vcd' in DBG:
            self._soc.enable_vcd_trace()

        for arg in DBG:
            if '+ticks_to_run' in arg:
                tick_num = int(arg.split('=')[1])
                self._soc.set_ticks_to_run(tick_num)
                break

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

    def print_utrace(self):
        s = []
        tick_ctr = self._soc._soc.counterGetTick()
        step_ctr = self._soc._soc.counterGetStep()
        for k in self._trace['states']:
            v = self._trace['states'][k]
            s.append('{}({})'.format(k, v))
        print('     - step: #{}, utick: {}'.format(step_ctr, tick_ctr))
        print('     - {} || tick#{}'.format(','.join(s), self._trace['tick_cnt']))
        self.process_input('watchpoint callback')

    def tracing_callback(self):

        self._trace['tick_cnt'] += 1
        new_state = self._soc._soc.cpuState()
        if new_state == self._bench.en_state.FETCH:
            if (self._trace['state'] != new_state):

                pc = self._soc.pc()
                msg = self._disasm.display(pc, self._soc)
                if msg != None:
                    print(msg)
                else:
                    print('{:#x}: DISASSEMBLER ERROR'.format(pc))
                self.print_utrace()
                print('')

                self._trace['states'].clear()

        self._trace['state'] = new_state
        if self._trace['states'].has_key(str(new_state)):
           self._trace['states'][str(new_state)] += 1
        else:
           self._trace['states'][str(new_state)] = 1

    def stepi(self, n):
        i = 0
        while i < n:
           self._cmd['step'].run('1')
           i = i + 1
        return None

    def preprocess_cmd(self, user_input):
        if user_input == None:
            return None
        input_cmd = [x.strip() for x in user_input.split()]
        input_cmd = [i for i in input_cmd if i]
        return input_cmd

    def process_input(self, user_input):
        input_cmd = self.preprocess_cmd(user_input)

        if len(input_cmd) == 0:
            if user_input == '': # if we have just hit "enter"
                input_cmd = self.preprocess_cmd(self._rerun)
                if input_cmd == None:
                    return
                if len(input_cmd) == 0:
                    return
                print ('#rerun cmd: {}'.format(' '.join(input_cmd)))
            else:
                if self._rerun != None:
                    print '#note rerun dropped'
                self._rerun = None

            if self._rerun == None:
              return

        cmd = input_cmd[0]
        input_cmd.pop(0)

        if self._cmd.has_key(cmd):
            if len(input_cmd) > 0:
              if input_cmd[0] == 'help':
                    self._cmd[cmd].help()
                    return
            self._rerun = self._cmd[cmd].run(input_cmd)
        else:
            print("Error: unknown command {}".format(cmd))

    def repl(self):
        self._soc.setResetPC()
        while True:
            try:
                user_input = prompt('>',
                    history=FileHistory('.history.txt'),
                    auto_suggest=AutoSuggestFromHistory(),
                )
            except KeyboardInterrupt:
                print 'got cntrl+C - terminating debug session'
                break
            except EOFError:
                print 'got EOF - terminating debug session'
                break

            self.process_input(user_input)


