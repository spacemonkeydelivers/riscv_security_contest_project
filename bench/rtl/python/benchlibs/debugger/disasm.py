import os
import shutil

class Disassembler:
    def __init__(self, path_to_elf):
        self._objdump = os.environ['TOOLCHAIN_DIR'] + '/bin/riscv32-unknown-elf-objdump'
        disasm_cmd = ' '.join([
              self._objdump,
              '-d test.elf | '
              'grep -E \'\\s*[0-9a-f]+\\:\\s+\''
            ])
        self._data = {
        }
        disasm = os.popen(disasm_cmd).read()
        filter_tmp = []
        lines = disasm.splitlines()
        lines.pop(0)
        for s in lines:
            split = s.split(':')
            addr = int(split[0], 16)
            split = split[1].strip().split('\t')
            try:
                raw = int(split[0], 16)
            except ValueError:
                continue
            inst = '\t'.join(split[1:])

            filter_tmp.append('{} {}::{}'.format(format(raw, '032b'),
                                                  hex(addr), inst))

            self._data[addr] = { "disas": inst, "raw": raw }
            #print self._data[addr]
        self.dump_filters(filter_tmp)

    def dump_filters(self, filter_tmp):
        if not os.path.exists('filters'):
            os.mkdir('filters')
        f = open('filters/DISASM.flt', 'w+')
        for item in filter_tmp:
            f.write('{}\n'.format(item))
        f.close()

        src = os.environ['TOOLS_DISTRIB'] + '/share/common_filters'
        for item in os.listdir(src):
            s = os.path.join(src, item)
            d = os.path.join('filters/', item)
            shutil.copy2(s, d)


    def dump(self):
        for k in self._data:
            print('{}:{}'.format(hex(k), self._data[k]))

    def display(self, address, soc):
        if ( self._data.has_key(address) ):
            info = self._data[address]
            raw   = info["raw"]
            disas = info["disas"]

            data = soc.read_word_ram(word_index = address / 4)
            if (address % 4) == 0:
                if (data & 3) != 3: # short instruction
                    data = data & 0xffff

                if raw != data:
                    return (
                    "DISASSEMBLER ERROR - text CORRUPTION detected!"
                    "content={:#x}, expected=[{:#x}, {}]"
                    ).format(data, raw, disas)
                else:
                    return '{:#x}:{} || raw: {:#04x}'.format(address, disas, raw)
            elif (address % 4) == 2:
                data_low = (data >> 16) & 0xffff
                if (data_low & 3) == 3: # we have an unaligned 4-byte instruction
                   data_high = soc.read_word_ram(word_index = address / 4 + 1) & 0xffff
                   data = data_low | (data_high << 16)
                else:
                   data = data_low
                if data == raw:
                    return '{:#x}:{} || raw: {:#x}'.format(address, disas, raw)
                else:
                    return (
                    "DISASSEMBLER ERROR - text CORRUPTION detected (2-byte border)!"
                    "content={:#x}, expected=[{:#x}, {}]"
                    ).format(data, raw, disas)
            else:
                return "DISASSEMBLER ERROR - unaligned address detected"
        else:
          return '{:#x}: DISASSEMBLER ERROR: NO DISASSEMBLY INFORMATION AVAILABLE'.format(address)
