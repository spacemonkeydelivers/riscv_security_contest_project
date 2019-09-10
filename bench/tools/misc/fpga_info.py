import subprocess
import sys
import os

nm_tool = os.environ['NM_TOOL']
elf_image = sys.argv[1]

output = sys.argv[2]

def read_symbol(symbol):
  cmd = "{}  {} | grep {} | awk '{{ print $1 }}'".format(nm_tool, elf_image, symbol)
  print(cmd)
  data = subprocess.check_output(cmd, shell=True)
  return data.strip()

print "exracting fpga info from <{}>".format(elf_image) # | awk '\{ print 1 }'

addr_test_exit = read_symbol('__marker_test_end')
addr_test_status = read_symbol('__marker_test_status')
bla = read_symbol('__marker_bla')

fpga_info =  '{{ "test_exit": "0x{}", "test_status": "0x{}" }}'.format(
                  addr_test_exit, addr_test_status)
print(fpga_info)

f = open(output, "w")
f.write(fpga_info)
f.close()

