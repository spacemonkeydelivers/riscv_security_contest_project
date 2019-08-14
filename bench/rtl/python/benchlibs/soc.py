import sys
import collections
from collections import deque

#TODO: logger instead of prints?
class RiscVSoc:
    def __init__(self, libbench, path_to_vcd, debug = False):
        self._soc = libbench.RV_SOC(path_to_vcd)
        self._bench = libbench
        self._debug = debug
        self._word_size = self._soc.wordSize()
        self._on_tick_callbacks = []

        self._prev_pc = None
        self._stall_cnt = 0
        self._pc_history = collections.deque(10 * [None], 10)

        self._last_state = None # for debug only
        self._fwd_state = None # NONE, FETCH or EXEC
        self._fwd_cntr = 0
        self._braindead_threshold = 50
        self._stall_threshold = self._braindead_threshold / 2 * 3

        self._uart = None
        import atexit
        atexit.register(self.printIO)

    def printIO(self):

        if self._uart == None:
            print("no uart output was detected")
            return

        print('...---...---...---...---')
        print('Behold! The UART(output) log follows:')
        print(open('io.txt', 'r').read())
        print('...---...---...---...---')

    def checkFWD(self):
        state = self._soc.cpuState()

        if (state == self._bench.en_state.FETCH) and (
            self._fwd_state == self._bench.en_state.EXEC):

          self._fwd_cntr = 0
          self._fwd_state = state
          # print('exec -> fetch')
        elif (state == self._bench.en_state.EXEC) and (
            self._fwd_state == self._bench.en_state.FETCH):
          self._fwd_cntr = 0
          self._fwd_state = state
          # print('fetch -> exec')
        else:
          if (state == self._bench.en_state.FETCH):
            self._fwd_state = state
          self._fwd_cntr = self._fwd_cntr + 1

        if (self._fwd_cntr > self._braindead_threshold):
           raise RuntimeError(
               "soc is braindead (not fetch -> exec transition detected for {} ticks)".format(self._braindead_threshold)
            )
        self._last_state = state
        # print(state)

    def setDebug(self, debug):
        self._debug = debug

    def register_tick_callback(self, callback):
        if self._debug:
            print("Registering on tick callback")
        self._on_tick_callbacks.append(callback)

    def go_step(self):
        if self._soc.pcValid():
            self._prev_pc = self._soc.PC()

        self.checkFWD()
        self.tick(1)

        if self._soc.pcValid():
            new_pc  = self._soc.PC()

            if (self._prev_pc == None):
                self._prev_pc = 0

            # print ("PC: 0x{0:08x} -> 0x{0:08x}".format(self._prev_pc, new_pc))

            if new_pc != self._prev_pc:
                self._stall_cnt = 0
                self._prev_pc = new_pc
                self._pc_history.append(new_pc)


        self._stall_cnt = self._stall_cnt + 1

    def go(self, limit, expect_failure = False):

        iterations = 0
        while (self._stall_cnt < self._stall_threshold):
            self.go_step()

            iterations = iterations + 1

            if (limit != None) and (iterations >= limit):
                print("\nlast known PC values:")
                for pc in self._pc_history:
                    if pc != None:
                      print("- 0x{0:08x}".format(pc))
                    else:
                      print("- n/a")
                msg = "simulation takes too long (more than {} steps)".format(limit)
                raise StopIteration(msg)

        print("hart does not make forward progress for too long. Assume test exit")
        status = self.read_register(1) # exit status is in ra

        if expect_failure:
          if status == 0:
              msg = "exit code <{}> indicates success, while tests expects failure".format(status)
              raise RuntimeError(msg)
        else:
          if status != 0:
              msg = "exit code <{}> indicates failure".format(status)
              raise RuntimeError(msg)

        print("exit code indicates success, test passed")

    def tick(self, ticks):
        for t in range(ticks):
            self._soc.tick(1)
            self.print_uart_tx()
            for c in self._on_tick_callbacks:
#                if self._debug:
#                    print("Calling on tick callback")
                c()

    def print_uart_tx(self):
        if self._soc.uartTxValid():
            character = str(chr(self._soc.readTxByte()))

            if self._uart == None:
                self._uart = open("io.txt", "w", 0)

            self._uart.write(character)

    def print_pc(self):
        if self._soc.pcValid():
            print("PC: 0x{0:08x}".format(self._soc.PC()))

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