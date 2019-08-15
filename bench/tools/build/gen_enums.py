import sys
import os

EN_CLASS    = []
PY_EN_WRAP  = []
ASM_DEFINES = []

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


import re

def common_matcher(line, prefix):
  m = re.match(r'\s*localparam\s+(\w+)\s*=\s*(\d+)\s*;', line)
  t = 'dec'
  if m == None:
    m = re.match(r'\s*localparam\s+(\w+)\s*=\s*\d+\'b(\d+)\s*;', line)
    t = 'bin'
  if m == None:
    m = re.match(r'\s*localparam\s+(\w+)\s*=\s*\d+\'h([0-9a-fA-F]+)\s*;', line)
    t = 'hex'

  if m == None:
    return None;

  en_item = m.group(1)
  if not en_item.startswith(prefix):
    return None

  en_item = en_item[len(prefix):]
  item_val = m.group(2)

  if t == 'bin':
    item_val = int(item_val, 2)
  elif t == 'hex':
    item_val = int(item_val, 16)
  else:
    item_val = item_val

  return { 'en_item': en_item, 'item_val': item_val }

gen_enum('en_state', 'rtl/cpu/cpu.v',
        lambda l: common_matcher(l, 'STATE_') )

gen_enum('en_mcause', 'rtl/cpu/cpu.v',
        lambda l: common_matcher(l, 'CAUSE_') )


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
