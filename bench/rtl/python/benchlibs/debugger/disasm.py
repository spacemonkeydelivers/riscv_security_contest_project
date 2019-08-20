import os

class Disassembler:
    def __init__(self, path_to_elf):
        self._objdump = os.environ['TOOLCHAIN_DIR'] + '/bin/riscv32-unknown-elf-objdump'
        disasm_cmd = ' '.join([
              self._objdump,
              '--no-show-raw-insn -d test.elf'
              ' | grep -E \'\\s*[0-9a-f]+\\:\\s+\''
            ])
        self._data = {
        }
        disasm = os.popen(disasm_cmd).read()
        lines = disasm.splitlines()
        lines.pop(0)
        for s in lines:
          split = s.split(':')
          addr = int(split[0], 16)
          inst = split[1]

          self._data[addr] = inst

    def dump(self):
        for k in self._data:
            print('{}:{}'.format(hex(k), self._data[k]))

    def display(self, address):
        if self._data.has_key(address):
            return '{}:{}'.format(hex(address), self._data[address])
        else:
            '{}: UNDEFINED'.format(hex(address))
