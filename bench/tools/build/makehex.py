#!/usr/bin/env python3

from sys import argv

binfile = argv[1]
hexfile = argv[2]

with open(binfile, "rb") as f:
    bindata = f.read()

hexdata = open(hexfile, 'w')

assert len(bindata) % 4 == 0

for i in range(len(bindata) // 4):
    w = bindata[4*i : 4*i+4]
    hexdata.write("%02x%02x%02x%02x\n" % (w[3], w[2], w[1], w[0]))

hexdata.close()
