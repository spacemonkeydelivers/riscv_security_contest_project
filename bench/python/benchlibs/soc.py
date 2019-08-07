#TODO: logger instead of prints?
class RiscVSoc:
    def __init__(self, libbench, path_to_vcd, debug = False):
        self._soc = libbench.RV_SOC(path_to_vcd)
        self._debug = debug
        self._word_size = self._soc.wordSize()
        self._on_tick_callbacks = []

    def register_tick_callback(self, callback):
        if self._debug:
            print("Registering on tick callback")
        self._on_tick_callbacks.append(callback)

    def tick(self, ticks):
        for t in range(ticks):
            self._soc.tick(1)
            for c in self._on_tick_callbacks:
#                if self._debug:
#                    print("Calling on tick callback")
                c()

    def print_uart_tx(self):
        if self._soc.uartTxValid():
            print(str(chr(self._soc.readTxByte())))

    def reset(self):
        self._soc.reset()

    def get_soc_ram_size(self):
        return self._soc.ramSize() * 4

    def load_data_to_ram(self, path_to_image, offset_in_words = 0):
        data = map(lambda x: x.strip(), open(path_to_image, "r").readlines())
        offset = 0
        for line in data:
            if line[0] == '@':
                offset = int(line[1:], 16) / 4
                if self._debug:
                    print("Changing offset while loading to RAM to: 0x{0:08x}".format(offset))
            else:
                b = line.split()
                for k in range(0, len(b), 4):
                    word = int("".join(b[k:k+4][::-1]), 16)
                    self._soc.writeWord(offset, word)
                    if self._debug:
                        print("Writing 0x{0:08x} to address 0x{1:08x}".format(word, offset * 4))
                    offset += 1

    def print_ram(self, start_addr = 0, num_words = 8):
        for addr in xrange(start_addr, start_addr + num_words):
            print("0x{0:08x} : 0x{1:08x}".format(addr * self._word_size, self._soc.readWord(addr)))

    def read_word_ram(self, address):
        if self._debug:
            print("Reading 0x{0:08x} from 0x{1:08x}".format(self._soc.readWord(address), address * self._word_size))
        return self._soc.readWord(address)

    def write_word_ram(self, address, value):
        if self._debug:
            print("Writing 0x{0:08x} to 0x{1:08x}".format(value, address * self._word_size))
        self._soc.writeWord(address, value)

    def pc(self):
        return self._soc.PC()

    def read_register(self, num):
        if self._debug:
            print("Reading 0x{0:08x} from {1:02d} register".format(self._soc.readReg(num), num))
        return self._soc.readReg(num)

    def write_register(self, num, value):
        if self._debug:
            print("Writing 0x{0:08x} to {1:02d} register".format(value, num))
        self._soc.writeReg(num, value)

    def print_register_file(self):
        for num in range(self._soc.regFileSize()):
            print("Register {0:02d} has value of 0x{1:08x}".format(num, self._soc.readReg(num)))
