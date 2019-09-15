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

        self._the_pc = -1
        self._stall_cnt = 0
        self._pc_history = collections.deque(10 * [None], 10)

        self._last_state = None # for debug only
        self._fwd_state = None # NONE, FETCH or EXEC
        self._fwd_cntr = 0
        self._braindead_threshold = 50
        self._stall_threshold = self._braindead_threshold / 2 * 3
        self._ticks_to_run = 5 * 10 ** 6
        self._min_address = 0

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

    def unregister_tick_callback(self, callback):
        if self._debug:
            print("UNregistering on tick callback")
        if callback in self._on_tick_callbacks:
            self._on_tick_callbacks.remove(callback)

    def tick(self):
        if self._soc.pcValid():
            self._the_pc = self._soc.PC()

        self.checkFWD()
        self._tick(1)

        if self._soc.pcValid():
            new_pc  = self._soc.PC()
            if new_pc != self._the_pc:
                self._stall_cnt = 0
                self._the_pc = new_pc
                self._pc_history.append(new_pc)

        self._stall_cnt = self._stall_cnt + 1

    def run(self, limit, expect_failure = False, break_on = None):
        self._soc.setPC(self._min_address)
        iterations = 0
        while (self._stall_cnt < self._stall_threshold):
            self.tick()

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

            if (break_on != None) and (self.pc() == break_on):
                raise UserWarning("breakpoint reached")

        print("hart does not make forward progress for too long. Assume test exit")
        status = self.read_register(1) # exit status is in ra

        SUCCESS_CODE = 0x0A11C001
        if expect_failure:
          if status == SUCCESS_CODE:
              msg = "exit code <{}> indicates success, while tests expects failure".format(status)
              raise RuntimeError(msg)
        else:
          if status != SUCCESS_CODE:
              msg = "exit code <{}> indicates failure".format(status)
              raise RuntimeError(msg)

        print("exit code indicates success, test passed")

    def _tick(self, ticks):
        self._soc.tick(1)
        self.print_uart_tx()
        for c in self._on_tick_callbacks:
            c()

    def print_uart_tx(self):
        if self._soc.uartTxValid():
            character = str(chr(self._soc.readTxByte()))

            if self._uart == None:
                self._uart = open("io.txt", "w", 0)

            self._uart.write(character)

    def reset(self):
        self._soc.reset()

    def get_soc_ram_size(self):
        return self._soc.ramSize() * 4

    def enable_vcd_trace(self):
        self._soc.enableVcdTrace()

    def get_ticks_to_run(self):
        return self._ticks_to_run

    def set_ticks_to_run(self, value):
        self._ticks_to_run = value

    def load_data_to_ram(self, path_to_image, offset_in_words = 0, external = False):
        self._min_address = 0
        addr_set = False
        if external:
            self._soc.toggleCpuReset(True)
            self._soc.switchBusMasterToExternal(True)
        data = map(lambda x: x.strip(), open(path_to_image, "r").readlines())
        offset = 0
        addr = 0
        for line in data:
            if line[0] == '@':
                print("#################################")
                addr = int(line[1:], 16)
                offset = addr / self._word_size
                if not addr_set:
                    self._min_address = addr
                    addr_set = True

                if self._debug:
                    print("Changing offset while loading to RAM to: 0x{0:08x}".format(offset))
                if (addr < self._min_address):
                    self._min_address = offset * self._word_size
            else:
                b = line.split()
                cur_addr = addr
                cur_len = len(b)
                cur_pos = 0
                while cur_len:
                    cur_align = cur_addr & 0b11
                    bytes_to_write = 0
                    addr_adjust = 0
                    cur_data = 0
                    addr_to_access = cur_addr / self._word_size
                    if cur_len >= (self._word_size - cur_align):
                        bytes_to_write = self._word_size - cur_align
                        addr_adjust = self._word_size - cur_align
                    else:
                        bytes_to_write = cur_len
                        addr_adjust = cur_len
                    if (cur_align != 0):
                        if external:
                            cur_data = self._soc.readWordExt(addr_to_access)
                        else:
                            cur_data = self._soc.readWord(addr_to_access)
                    mask = 0
                    if (bytes_to_write == 1):
                        mask = 0xff << cur_align * 8
                    elif (bytes_to_write == 2):
                        mask = 0xffff << cur_align * 8
                    elif (bytes_to_write == 3):
                        mask = 0xffffff << cur_align * 8
                    else:
                        mask = 0xffffffff
                    byte_data = b[cur_pos:cur_pos + bytes_to_write]
                    for i in range(self._word_size - bytes_to_write):
                        if cur_align:
                            byte_data.insert(0, "00")
                        else:
                            byte_data.append("00")
                    data = int("".join(byte_data[::-1]), 16)

                    data_to_write = (~mask & cur_data) | (data)
                    if external:
                        self._soc.writeWordExt(addr_to_access, data_to_write)
                    else:
                        self._soc.writeWord(addr_to_access, data_to_write)
                    if self._debug:
                        print("Writing 0x{0:08x} to address 0x{1:08x}".format(data_to_write, addr_to_access * self._word_size))
                    cur_len -= addr_adjust
                    cur_addr += addr_adjust
                    cur_pos += bytes_to_write
                addr = cur_addr
        if external:
            self._soc.toggleCpuReset(False)
            self._soc.switchBusMasterToExternal(False)


    def print_ram(self, start_word_index = 0, num_words = 8, external = False):
        if external:
            self._soc.toggleCpuReset(True)
            self._soc.switchBusMasterToExternal(True)
        for w_idx in xrange(start_word_index, start_word_index + num_words):
            if external:
                print("0x{0:08x} : 0x{1:08x}".format(w_idx * self._word_size, self._soc.readWordExt(w_idx)))
            else:
                print("0x{0:08x} : 0x{1:08x}".format(w_idx * self._word_size, self._soc.readWord(w_idx)))
        if external:
            self._soc.toggleCpuReset(False)
            self._soc.switchBusMasterToExternal(False)

    def read_word_ram(self, word_index = None):
        if (word_index == None):
            raise ValueError("word_index argument must be specified")
        if self._debug:
            print("Reading 0x{0:08x} from 0x{1:08x}".format(self._soc.readWord(word_index), word_index * self._word_size))

        try:
          result =  self._soc.readWord(word_index)
          return result
        except IndexError, e:
          print '#error during memory read detected <{}>'.format(e)
          return None



    def write_word_ram(self, address, value):
        if self._debug:
            print("Writing 0x{0:08x} to 0x{1:08x}".format(value, address * self._word_size))
        self._soc.writeWord(address, value)

    def pc(self):
        return self._the_pc

    def upc(self):
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
