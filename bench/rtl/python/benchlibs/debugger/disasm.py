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
        if self._data.has_key(address):
            info = self._data[address]
            raw   = info["raw"]
            disas = info["disas"]

            data = soc.read_word_ram(word_index = address / 4)
            if data == raw:
              return '{}:{}'.format(hex(address), disas)
            else:
              return 'disasm failure. text CORRUPTION detected! content={:#x}, expected=[{:#x}, {}]'.format(
                  data, raw, disas)
        else:
            '{}: UNDEFINED'.format(hex(address))
