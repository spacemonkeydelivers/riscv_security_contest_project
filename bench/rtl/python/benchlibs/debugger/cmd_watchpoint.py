from collections import OrderedDict

REG_NAMES = {
  0: 'x0',
  1: 'ra',  2: 'sp',  3: 'gp',  4: 'tp',
  5: 't0',  6: 't1',  7: 't2',
  8: 's0',  9: 's1',
  10: 'a0', 11: 'a1',
  12: 'a2', 13: 'a3', 14: 'a4', 15: 'a5', 16: 'a6', 17: 'a7',
  18: 's2', 19: 's3', 20: 's4', 21: 's5', 22: 's6', 23: 's7',
  24: 's8', 25: 's9', 26: 's10', 27: 's11',
  28: 't3', 29: 't4', 30: 't5',  31: 't6'
}

#(NOTE) Hvatit li Toly kondratiy?
REG_INDEXES = dict([(value, key) for key, value in REG_NAMES.items()])
class CmdWatchpoint:
    def __init__(self, benchlib, soc, debugger):
        self.soc = soc
        self.bench = benchlib
        self.debugger = debugger
        self.watchpoints = {} #{'a':['test1', 'test2'], 'b':['test3', 'test4']}
        self._word_size = 4#self.soc.wordSize()
        self.watchpoint_table_size = 0

    def names(self):
        return ['watchpoint', 'w']

    def help(self):
        print("\n".join(['"watchpoint" command.',
          'Synopsys: command prints value of changed register or memory by means of 4 bytes.',
          'Command requires either [reg]ister or [mem]ory modifier.',
          'Example usage:',
          'watchpoint reg x1',
          'watchpoint mem 0x04',
          ]))

    def add_register_watchpoint(self, args):
        # w add reg x0
        if ( len(args) < 3 ):
            print '[-] Insufficient number of arguments passed. Add register identifier.'
            return None

        register = args[2]
        index = REG_INDEXES.get(register)

        if ( index == None ):
            print '[-] Have not found register in CPU Register file.'
            return None
        
        register_value = self.soc.read_register(index)
        self.watchpoints[self.watchpoint_table_size] = [register, hex(register_value), 'register']
        self.watchpoint_table_size += 1
        print '[+] Watchpoint {} is set. Watching register: {}, current value: {}'.format(
            self.watchpoint_table_size,
            self.watchpoints[self.watchpoint_table_size - 1][0],
            self.watchpoints[self.watchpoint_table_size - 1][1],
            )

    def add_memory_watchpoint(self, args):
        # w add mem 0x1337
        if ( len(args) < 3 ):
            print '[-] Insufficient number of arguments passed. Add address to watch.'
            return None

        address = int(args[2][2:],16) #Cutting 0x off
        word_index = address / self._word_size
        memory_value = self.soc.read_register(word_index)

        self.watchpoints[self.watchpoint_table_size] = [
            hex(address), 
            hex(self.soc.read_word_ram(word_index)),
            'memory',
            ]
        self.watchpoint_table_size += 1
        print '[+] Watchpoint {} is set. Watching memory address: {}, index: {}, current value: {}'.format(
            self.watchpoint_table_size - 1,
            self.watchpoints[self.watchpoint_table_size - 1][0],
            word_index,
            self.watchpoints[self.watchpoint_table_size - 1][1],
            )
    
    def watchpoint_callback(self):
        # (IC) Python dictionaries evaluates to False if empty.
        if ( self.watchpoints != False):
            for key, watchpoint in self.watchpoints.iteritems():
                trigger = watchpoint[0]
                saved_value = watchpoint[1]
                location = watchpoint[2]
                
                if ( location == 'register'):
                    #print 'Testing register callback'
                    index = REG_INDEXES.get(trigger)
                    current_value = self.soc.read_register(index)
                    if ( int(saved_value[2:], 16) != current_value ):
                        print '\t[*] Watchpoint {} hit. Register {} changed its value from {} to {}'.format(
                            key,
                            trigger,
                            saved_value,
                            hex(current_value),
                            )
                        self.watchpoints[key] = [trigger, hex(current_value), location]
                
                if ( location == 'memory'):
                    #print 'Testing register memory'
                    address = int(trigger[2:],16) #Cutting 0x off
                    word_index = address / self._word_size
                    memory_value = self.soc.read_register(word_index)

                    current_value = self.soc.read_word_ram(word_index)
                    if ( int(saved_value[2:], 16) != current_value ):
                        print '\t[*] Watchpoint {} hit. Value at address {} changed its value from {:08X} to {08X}'.format(
                            key,
                            trigger,
                            saved_value,
                            hex(current_value),
                            )
                        self.watchpoints[key] = [trigger, hex(current_value), location]

    def run(self, args):
        if ( len(args) == 0 ):
            print '[-] Insufficient number of arguments passed'
            self.help()
            return None

        if ( args[0] == 'add' ):
            if ( len(args) < 2 ):
                print '[-] Insufficient number of arguments passed. Use either "reg" or "mem".'
                return None
            if (args[1] == 'reg'):
                self.add_register_watchpoint(args)
            elif (args[1] == 'mem'):
                self.add_memory_watchpoint(args)
            else:
                print '[-] Wrong argument. Use either "reg" or "mem".'
            return None
       
        if ( args[0] == 'rem' ):
            if ( len(args) < 2 ):
                print '[-] Insufficient number of arguments passed. Specify watchpoint to delete.'
                return None
            try:
                index = args[1]
                self.watchpoints.pop(int(index))
                print '[+] Watchpoint {} successfully removed'.format(int(index))
            except:
                print '[-] Invalid watchpoint to delete.'
            return None
            
        if ( args[0] == 'callback'):
            self.watchpoint_callback()
            return None 

        if ( args[0] == 'show'):
            print 'Watchpoints: {}'.format(self.watchpoints)
            print REG_INDEXES
            return None
       
        print('Error: incorrect <watchpoint> command')
        return None

