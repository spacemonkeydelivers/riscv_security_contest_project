import re

class CmdExamine:
    def __init__(self, benchlib, soc, debugger):
        self.soc = soc
        self.bench = benchlib
        self.debugger = debugger

    def names(self):
        return ['examine', 'x']

    def help(self):
        print("\n".join(['"examine" command',
          'Synopsis: {examine|x} [/format] addr',
          'Examine contents of memory formatting results according to the specified format.',
          '`format` has the following form <d|u|x|t|i>[b|h|w][number]',
          '  <d|u|x|t|i>: output format specifier. d - decimal, u - unsigned, '
          'x - hex, t - binary, i - instruction.',
          '  [b|h|w]: how to interpret input. b - byte, h - 2 bytes, w - 4 bytes (default).',
          '  number: how many items to display. can be negative (reverses memorty scan)'
          ]))

    def read_data (self, fmt, num, addr):
        reverse = False
        el_sz = 4
        if fmt == 'b':
            el_sz = 1
        if fmt == 'h':
            el_sz = 2

        if (num < 0):
            num = -num
            addr = addr - num * el_sz
            reverse = True

        total_bytes = el_sz * num
        total_words = total_bytes / 4 + (1 if (total_bytes % 4) > 0 else 0)

        result = []
        start_a = addr
        end_a = addr + num * el_sz
        for i in range(0, total_words):
          s_addr = addr + i * 4
          if s_addr < 0:
              continue
          word = self.soc.read_word_ram(word_index = s_addr)
          if word == None:
              return None
          if fmt == 'b':
             a = [ s_addr + 0, s_addr + 1, s_addr + 2, s_addr + 3]
             d = [ word & 0xff, (word >> 8) & 0xff, (word >> 16) & 0xff, (word >> 24) & 0xff]
          elif fmt == 'h':
             a = [ s_addr + 0, s_addr + 2]
             d = [ (word & 0xff) | (word & 0xff00), ((word >> 16) & 0xff) | ((word >> 16) & 0xff00)]
          else:
             a = [ s_addr]
             d = [ word ]

          for i in range(0, len(a)):
              ra = a[i]
              if (ra >= s_addr) and (ra < end_a):
                  result.append([ra, d[i]])
        return result

    def run(self, args):

        if (len(args) == 2):
            m = re.match(r'/([duxti])([bhw]?)([-]?[0-9a-fA-f]*)', args[0])
            if m != None:
              try:
                out   = m.group(1)
                inpt  = m.group(2)
                if inpt == '':
                  inpt = 'w'
                number = m.group(3)
                if number == '':
                  number = '1'
                number = int(number)
                addr  = int(args[1], 0)

                if out == 'i':
                  inpt = 'w'

                if (addr % 4) != 0:
                  print('Error: only word-aligned addresses supported at the moment')
                  raise ValueError('unimplemented')

                width = 8
                if inpt == 'h':
                  width = 4
                if inpt == 'b':
                  width = 2
                if (out == 't'):
                  width = width * 4
                data = self.read_data(inpt, number, addr)
                if data == None:
                    print('Error: examining memory failed')
                    return None
                fmts = {
                  'd': '{0:#010x}: {1}',
                  'u': '{0:#010x}: {1}',
                  'x': '{0:#010x}: {1:#0' + str(width + 2) + 'x}',
                  't': '{0:#010x}: {1:#0' + str(width + 2) + 'b}',
                  'i': '{0:#010x}: {1}',
                }
                for d in data:
                    a = d[0]
                    d = d[1]
                    if ( out != 'i' ):
                        print(fmts[out].format(a, d))

                    if out == 'i':
                        err_count = 0
                        msg1 = self.debugger._disasm.display(a, self.soc)
                        if ("DISASSEMBLER ERROR" not in msg1) or ("CORRUPTION" in msg1):
                            m = ':'.join(msg1.split(':')[1:])
                            print(fmts[out].format(a, m))
                        else:
                            err_count = err_count + 1

                        msg2 = self.debugger._disasm.display(a + 2, self.soc)
                        if ("DISASSEMBLER ERROR" not in msg2) or ("CORRUPTION" in msg2):
                            m = ':'.join(msg2.split(':')[1:])
                            print(fmts[out].format(a + 2, m))
                        else:
                            err_count = err_count + 1

                        if err_count == 2:
                          print('{:#x}: {}'.format(a, msg1))
                          print('{:#x}: {}'.format(a + 2, msg2))

                print('_______________________')

                if out == 't':
                  i_w = width / 8
                else:
                  i_w = width / 2
                rerun_addr = addr + number * i_w
                return 'x /{0:}{1:}{2:} {3:#x}'.format(out, inpt, number, rerun_addr)
              except ValueError:
                print 'Error: could not parse format string'
        print('Error: incorrect <examine> command')
        return None

