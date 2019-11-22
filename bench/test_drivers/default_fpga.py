#!/usr/bin/python2

import sys
import os
import subprocess
import glob
import imp
import re
import time

#TODO: rename libbench to libdut
import libbench
import dut_wrapper.fpga as soc_lib

from benchlibs.image_loader import ImageLoader

def main(filename, opts, runner_override = None):
    if not os.path.isfile(filename):
        print 'could not find input file <{}>'.format(filename)
        raise RuntimeError('incorrect input file')

    #TODO: rename libbench to libdut
    soc = soc_lib.FPGA_SOC(libbench, "/dev/fpga")

    print("...fpga_init")
    soc.fpga_init()
    print("...check_sanity")
    soc.check_sanity()
    print("...halt_soc")
    soc.halt_soc()

    print("...set_baud")
    soc.uart_set_baud_9600()

    soc.uart_print("\nNew testing sequence initiated!\n")
    soc.uart_print("Uploading memory image...\n")
    ImageLoader.load_image(filename, soc)
    soc.uart_print("Memory image uploaded, initiating test run\n")
    soc.uart_print("----->\n")

    soc.print_cpu_status(halt = False)
    soc.run_soc(single_step = True)
    soc.print_cpu_status(halt = False)
#    time.sleep(1)
#    soc.print_cpu_status(halt = False)

    soc.run_in_singlestep(debug = True)
#    for i in range(1000000):
#        soc.do_step(debug = True
    soc.halt_soc()
    soc.print_cpu_status(halt = False)
    print("#######################")
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
    #soc.print_ram(0, 40)
    # soc.print_ram(0x100, 2)


if __name__ == '__main__':
    main(sys.argv[1])
