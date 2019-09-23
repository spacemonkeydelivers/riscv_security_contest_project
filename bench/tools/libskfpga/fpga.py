import libbench
import os
import sys
import time


class FPGA_SOC:
    REGISTER_SANITY         = 0x0
    REGISTER_ADDR_LOW       = 0x2
    REGISTER_ADDR_HIGH      = 0x4
    REGISTER_DATA_IN_LOW    = 0x6
    REGISTER_DATA_IN_HIGH   = 0x8
    REGISTER_CONTROL        = 0xa
    REGISTER_DATA_OUT_LOW   = 0xc
    REGISTER_DATA_OUT_HIGH  = 0xe
    REGISTER_CPU_PC_LOW     = 0x10
    REGISTER_CPU_PC_HIGH    = 0x12
    REGISTER_CPU_STATE      = 0x14
    SANE_CONSTANT           = 0x50FE
    BIT_CPU_RESET             = 0
    BIT_SOC_RESET             = 1
    BIT_BUS_MASTER            = 2
    BIT_TRANSACTION_START     = 3
    BIT_TRANSACTION_WRITE     = 4
    BIT_TRANSACTION_CLEAN     = 5
    BIT_TRANSACTION_READY     = 6
    BIT_TRANSACTION_SIZE_LOW  = 7
    BIT_TRANSACTION_SIZE_HIGH = 8
    BIT_CPU_HALT              = 9
    UART_BAUDE_DIVIDER_ADDR   = 0x80000000
    UART_TRANSMIT_BYTE_ADDR   = 0x80000004
    UART_9600_DIVIDER         = 13889
    def  __init__(self, fpga_dev):
        self._soc = libbench.skFpga(fpga_dev)
        self._firmware_uploaded = False
        self._control_reg = 0
    
    def upload_firmware(self, firmware_path):
        pass
#        self._soc.uploadBitstream(firmware_path)

    def get_cpu_state(self):
        # halt cpu
        self.__set_cpu_halt()
        self.__update_control_register()
        # get pc
        state = self._soc.readShort(self.REGISTER_CPU_STATE) & 0xFFFF
        # run cpu
        self.__clear_cpu_halt()
        self.__update_control_register()
        return state

    def print_cpu_state(self):
        state = self.get_cpu_state()
        print("CPU state: {0}".format(state))

    def get_cpu_pc(self):
        # halt cpu
        self.__set_cpu_halt()
        self.__update_control_register()
        # get pc
        low_pc = self._soc.readShort(self.REGISTER_CPU_PC_LOW) & 0xFFFF
        high_pc = self._soc.readShort(self.REGISTER_CPU_PC_HIGH) & 0xFFFF
        # run cpu
        self.__clear_cpu_halt()
        self.__update_control_register()
        return ((high_pc << 16) | low_pc)

    def print_cpu_pc(self):
        pc = self.get_cpu_pc()
        print("PC: 0x{:08X}".format(pc))

    def print_ram(self, start_address, num_words):
        print("{:10} : {:10}".format("address", "data"))
        for w in range(num_words):
            addr = start_address + w * 4
            data = self.read_word(addr)
            print("0x{:08X} : 0x{:08X}".format(addr, data))

    def upload_image(self, path_to_image):
        self._min_address = 0
        addr_set = False
        data = map(lambda x: x.strip(), open(path_to_image, "r").readlines())
        offset = 0
        addr = 0
        for line in data:
            if line[0] == '@':
                addr = int(line[1:], 16)
                offset = addr / 4
                if not addr_set:
                    self._min_address = addr
                    addr_set = True

                print("Changing offset while loading to RAM to: 0x{0:08x}".format(offset))
                if (addr < self._min_address):
                    self._min_address = offset * 4
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
                    addr_to_access = cur_addr / 4
                    if cur_len >= (4 - cur_align):
                        bytes_to_write = 4 - cur_align
                        addr_adjust = 4 - cur_align
                    else:
                        bytes_to_write = cur_len
                        addr_adjust = cur_len
                    if (cur_align != 0):
                        cur_data = self.read_word(addr_to_access)
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
                    for i in range(4 - bytes_to_write):
                        if cur_align:
                            byte_data.insert(0, "00")
                        else:
                            byte_data.append("00")
                    data = int("".join(byte_data[::-1]), 16)

                    data_to_write = (~mask & cur_data) | (data)
                    self.write_word(addr_to_access, data_to_write)
                    print("Writing 0x{0:08x} to address 0x{1:08x}".format(data_to_write, addr_to_access * 4))
                    cur_len -= addr_adjust
                    cur_addr += addr_adjust
                    cur_pos += bytes_to_write
                addr = cur_addr

    def fpga_init(self):
        self._soc.setReset(False)
        self._soc.setReset(1)
    
    def check_sanity(self):
        tmp = self._soc.readShort(self.REGISTER_SANITY)
        print(hex(tmp))
        assert(tmp == self.SANE_CONSTANT)
        return (tmp == self.SANE_CONSTANT)
   
    def halt_soc(self):
        # set cpu to reset
        self.__set_cpu_halt()
        # set soc to run
        self.__clear_soc_reset()
        # set bus to external
        self.__set_bus_master_external()
        # set tran width to word
        self.__set_transaction_size_to_word()
        self.__update_control_register()

    def run_soc(self):
        self.__clear_cpu_halt()
        self.__set_cpu_reset()
        # set soc to reset
#        self.__set_soc_reset()
        # set bus to cpu
        self.__set_bus_master_cpu()
        self.__update_control_register()
        # set cpu to run
        self.__clear_cpu_reset()
        # set soc to run
        self.__clear_soc_reset()
        self.__update_control_register()

    def uart_set_baud_9600(self):
        self.write_word(self.UART_BAUDE_DIVIDER_ADDR, self.UART_9600_DIVIDER)

    def uart_print(self, data):
        string = str(data)
        for ch in string:
            self.write_word(self.UART_TRANSMIT_BYTE_ADDR, ord(ch))

    def read_word(self, address):
        # set address
        self.__set_address(address)
        # prepare for read transaction
        self.__prepare_for_read_transaction()
        # run control
        self.__start_transaction()
        # check transaction finished
        finished = False
        for i in range(10):
            if self.__check_transaction_finished():
                finished = True
                break
        # clear transaction
        if not finished:
            print("tran is not finished successfully")
            return 0
        else:
            self.__clear_transaction_finished()
        return self.__get_data_out()

    def write_word(self, address, data):
        # set address
        self.__set_address(address)
        # set data
        self.__set_data_in(data)
        # prepare control
        self.__prepare_for_write_transaction()
        # run control
        self.__start_transaction()
        # check transaction finished
        finished = False
        for i in range(10):
            if self.__check_transaction_finished():
                finished = True
                break
        # clear transaction
        if not finished:
            print("tran is not finished successfully")
            return False
        else:
            self.__clear_transaction_finished()
        return True
        # check written ??

    def __update_control_register(self):
        self._soc.writeShort(self.REGISTER_CONTROL, self._control_reg)

    def __prepare_for_write_transaction(self):
        # set transaction write
        self.__set_transaction_write()
        pass

    def __prepare_for_read_transaction(self):
        pass

    def __start_transaction(self):
        self.__set_transaction_start()
        self.__update_control_register()

    def __check_transaction_finished(self):
        return self.__check_transaction_ready()

    def __clear_transaction_finished(self):
        # clear tran we
        self.__clear_transaction_write()
        # set tran clean
        self.__set_transaction_clean()
        self.__update_control_register()
        # clear tran clean
        self.__clear_transaction_clean()
        self.__update_control_register()

    def __set_control_bit(self, bit_pos):
        self._control_reg |= (1 << bit_pos)

    def __clear_control_bit(self, bit_pos):
        self._control_reg &= ~(1 << bit_pos)

    def __check_control_bit(self, bit_pos):
        self._control_reg = self._soc.readShort(self.REGISTER_CONTROL)
        res = (self._control_reg & (1 << bit_pos))
        return res

    def __set_address(self, address):
        low_addr = address & 0xFFFF
        self._soc.writeShort(self.REGISTER_ADDR_LOW, low_addr)
        high_addr = address >> 16
        self._soc.writeShort(self.REGISTER_ADDR_HIGH, high_addr)
        assert(address == self.__get_address())

    def __get_address(self):
        low_addr = self._soc.readShort(self.REGISTER_ADDR_LOW) & 0xFFFF
        high_addr = self._soc.readShort(self.REGISTER_ADDR_HIGH) & 0xFFFF
        return ((high_addr << 16) | low_addr)
    
    def __set_data_in(self, data):
        low_data_in = data & 0xFFFF
        self._soc.writeShort(self.REGISTER_DATA_IN_LOW, low_data_in)
        high_data_in = data >> 16
        self._soc.writeShort(self.REGISTER_DATA_IN_HIGH, high_data_in)
        assert(data == self.__get_data_in())

    def __get_data_in(self):
        low_data_in = self._soc.readShort(self.REGISTER_DATA_IN_LOW) & 0xFFFF
        high_data_in = self._soc.readShort(self.REGISTER_DATA_IN_HIGH) & 0xFFFF
        return ((high_data_in << 16) | low_data_in)

    def __get_data_out(self):
        low_data_out = self._soc.readShort(self.REGISTER_DATA_OUT_LOW) & 0xFFFF
        high_data_out = self._soc.readShort(self.REGISTER_DATA_OUT_HIGH) & 0xFFFF
        return ((high_data_out << 16) | low_data_out)

    def __set_cpu_halt(self):
        self.__set_control_bit(self.BIT_CPU_HALT)

    def __clear_cpu_halt(self):
        self.__clear_control_bit(self.BIT_CPU_HALT)

    def __set_cpu_reset(self):
        self.__set_control_bit(self.BIT_CPU_RESET)

    def __clear_cpu_reset(self):
        self.__clear_control_bit(self.BIT_CPU_RESET)

    def __set_soc_reset(self):
        self.__set_control_bit(self.BIT_SOC_RESET)

    def __clear_soc_reset(self):
        self.__clear_control_bit(self.BIT_SOC_RESET)

    def __set_bus_master_external(self):
        self.__set_control_bit(self.BIT_BUS_MASTER)

    def __set_bus_master_cpu(self):
        self.__clear_control_bit(self.BIT_BUS_MASTER)

    def __set_transaction_start(self):
        self.__set_control_bit(self.BIT_TRANSACTION_START)
    
    def __set_transaction_clean(self):
        self.__set_control_bit(self.BIT_TRANSACTION_CLEAN)

    def __clear_transaction_clean(self):
        self.__clear_control_bit(self.BIT_TRANSACTION_CLEAN)

    def __set_transaction_write(self):
        self.__set_control_bit(self.BIT_TRANSACTION_WRITE)

    def __clear_transaction_write(self):
        self.__clear_control_bit(self.BIT_TRANSACTION_WRITE)

    def __check_transaction_ready(self):
        return self.__check_control_bit(self.BIT_TRANSACTION_READY)

    def __set_transaction_size_to_word(self):
        self.__set_control_bit(self.BIT_TRANSACTION_SIZE_LOW)
        self.__set_control_bit(self.BIT_TRANSACTION_SIZE_HIGH)

soc = FPGA_SOC("/dev/fpga")
#soc.upload_firmware("/mnt/smd/bitstream/fpga.bit")
soc.fpga_init()
soc.check_sanity()
soc.halt_soc()

soc.uart_set_baud_9600()
soc.uart_print("Test")

#for i in range(32, 127):
#    soc.write_word(0x80000004, i)

print("#######################")

soc.upload_image("/mnt/smd/fpga_tests/asm_uart.v")
#soc.upload_image("/mnt/smd/fpga_tests/libc_printk.v")

#soc.write_word(0x0,  0x10000113)
#soc.write_word(0x4,  0x12300513)
#soc.write_word(0x8,  0x20000593)
#soc.write_word(0xc,  0x00a12023)
#soc.write_word(0x10, 0x00b50633)
#soc.write_word(0x14, 0x00c12223)
#soc.write_word(0x18, 0x0a11c0b7)
#soc.write_word(0x1c, 0x00108093)
#soc.write_word(0x20, 0x0000006f)

soc.print_ram(0, 40)

soc.run_soc()

time.sleep(3)

soc.print_cpu_pc()
soc.print_cpu_state()

soc.halt_soc()
#
print("#######################")
soc.print_ram(0x100, 2)

print(hex(soc.get_cpu_pc()))
print(soc.get_cpu_state())
