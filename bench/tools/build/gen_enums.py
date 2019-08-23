#!/usr/bin/env python3

import sys
import os

EN_CLASS    = []
PY_EN_WRAP  = []
ASM_DEFINES = []
EN_FILTER   = {}

def gen_enum(tgt_type, filename, matcher):
  matched_data = []
  input_file = os.path.join(sys.argv[1], filename)
  with open(input_file) as inf:
     for line in inf:
       m = matcher(line)
       if m != None:
         matched_data.append(m)

  if len(matched_data) == 0:
    raise Exception("no matches found")

  EN_CLASS.append('// Autogenrated from <{}>'.format(input_file))
  EN_CLASS.append('enum class {} : uint {{'.format(tgt_type))
  for item in matched_data:
    EN_CLASS.append('    {} = {}, '.format(item['en_item'], item['item_val']))
  EN_CLASS.append('};')

  # print('BOOST_PYTHON_MODULE(enums) {')
  PY_EN_WRAP.append('enum_<{}>("{}")'.format(tgt_type, tgt_type))
  for item in matched_data:
    PY_EN_WRAP.append('    .value("{}", {}::{})'.format(
      item['en_item'], tgt_type, item['en_item']))
  PY_EN_WRAP.append('    ;')

  ASM_DEFINES.append('// {} start'.format(tgt_type))
  for item in matched_data:
    ASM_DEFINES.append('#define  {}_{} {}'.format(
        tgt_type.upper(), item['en_item'], item['item_val']))
  ASM_DEFINES.append('// {} end\n'.format(tgt_type))

  filter_tmp = []
  for item in matched_data:
    # skip filter creation if size is not specified
    if item['item_size'] == None:
      continue
    filter_tmp.append('{} {}'.format(
        format(int(item['item_val']),
               '0{}b'.format(item['item_size'])),
        item['en_item']))
  EN_FILTER[tgt_type] = filter_tmp


import re
import warnings

def common_matcher(line, header, prefix):
  if header == 'localparam':
    m = re.match('\s*localparam\s+(\w+)\s*=\s*(\d+)\s*;', line)
    t = None
    if m == None:
      m = re.match('\s*localparam\s+(\w+)\s*=\s*(\d+)\'d(\d+)\s*;', line)
      t = 'dec'
    if m == None:
      m = re.match(r'\s*localparam\s+(\w+)\s*=\s*(\d+)\'b(\d+)\s*;', line)
      t = 'bin'
    if m == None:
      m = re.match(r'\s*localparam\s+(\w+)\s*=\s*(\d+)\'h([0-9a-fA-F]+)\s*;', line)
      t = 'hex'
  elif header == 'define':
    m = re.match(r'\s*`define\s*(\w+)\s*(\d+)\'b(\d+)\s*.*', line)
    t = 'bin'

  if m == None:
    return None;

  en_item = m.group(1)
  if not en_item.startswith(prefix):
    return None
  en_item = en_item[len(prefix):]

  if t == None:
    item_val  = m.group(2)
    item_size = None
    warnings.warn('Filter cannot be created for the target: \
{}\nline:\n> {}value of the element must be specified \
in a form that includes size'.format(prefix, line))
  else:
    item_val  = m.group(3)
    item_size = m.group(2)

  if t == 'bin':
    item_val = int(item_val, 2)
  elif t == 'hex':
    item_val = int(item_val, 16)

  return { 'en_item': en_item, 'item_val': item_val, 'item_size': item_size }

gen_enum('en_state', 'rtl/cpu/cpu.v',
        lambda l: common_matcher(l, 'localparam', 'STATE_') )

gen_enum('en_mcause', 'rtl/cpu/cpu.v',
        lambda l: common_matcher(l, 'localparam', 'CAUSE_') )

gen_enum('en_opcode', 'rtl/cpu/riscvdefs.vh',
        lambda l: common_matcher(l, 'define', 'OP_') )


print('#ifndef D_SOC_HEADER_INCLUDE__GUARD')
print('#define D_SOC_HEADER_INCLUDE__GUARD')
print('#ifdef __cplusplus ')
print('\n'.join(EN_CLASS))
print('#endif // __cplusplus')

print('#define __SOC_IS_NOT_SYSTEM_CONFORMANT')
print('\n'.join(ASM_DEFINES))
print('#endif // D_SOC_HEADER_INCLUDE__GUARD')

print('')

print('#ifdef D_GENERATE_SOC_ENUMS')
print('\n'.join(PY_EN_WRAP))
print('#endif // D_GENERATE_SOC_ENUMS')

filters_path = os.environ['DISTRIB_TOOLS_SHARE'] + '/common_filters'
if not os.path.exists(filters_path):
  os.mkdir(filters_path)
for key, value in EN_FILTER.items():
  f = open('{}/{}.flt'.format(filters_path, key.upper()), 'w+')
  for item in value:
    f.write('{}\n'.format(item))
  f.close()
