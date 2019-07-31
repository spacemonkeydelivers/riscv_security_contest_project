#TODO: logger instead of prints?

class RiscVSoc:
    def __init__(self, path_to_vcd, debug = False):
        self._soc = libbench.RV_SOC(path_to_vcd)
        self._debug = debug
        self._word_size = self._soc.wordSize()

    def tick(self, ticks):
        self._soc.tick(ticks)

    def reset(self):
        self._soc.reset()

    def get_soc_ram_size(self):
        return self._soc.ramSize()

    def load_data_to_ram(self, path_to_image, offset_in_words = 0):
        data = map(lambda x: int(x.strip(), 16), open(path_to_image, "r").readlines())
        if self._debug:
            print("Read {0} words".format(len(data)))
        words_left = self.get_soc_ram_size() - offset_in_words
        words_to_write = len(data)
        if len(data) > words_left:
            words_to_write = words_left
            if self._debug:
                print("Read too many words.")
        if self._debug:
            print("Writing data starting from 0x{0:08x} words {1}".format(offset_in_words * self._word_size, words_to_write))
        for i in range(words_to_write):
            if self._debug:
                print("Writing 0x{0:08x} to 0x{1:08x}".format(data[i], (i + offset_in_words) * self._word_size))
            self._soc.writeWord(i + offset_in_words, data[i])

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

soc = RiscVSoc('memtest_trace.vcd', True)
soc.load_data_to_ram("/tmp/rv_mem.txt")
soc.print_ram()
soc.tick(100)
soc.print_register_file()
print(hex(soc.pc()))
