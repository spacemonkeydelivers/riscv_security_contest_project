import sys
import os

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

  print('// Autogenrated from <{}>'.format(input_file))
  #matched_data.sort()
  print('#ifndef D_GENERATE_SOC_ENUMS')
  print('#ifndef D_SOC_HEADER_INCLUDE__GUARD')
  print('#define D_SOC_HEADER_INCLUDE__GUARD')
  print('enum class {} : int {{'.format(tgt_type))
  for item in matched_data:
    print('    {} = {}, '.format(item['en_item'], item['item_val']))
  print('};')
  print('#endif // D_SOC_HEADER_INCLUDE__GUARD')
  print('#endif // D_GENERATE_SOC_ENUMS')

  print('')
  print('')
  print('#ifdef D_GENERATE_SOC_ENUMS')
  # print('BOOST_PYTHON_MODULE(enums) {')
  print('enum_<{}>("{}")'.format(tgt_type, tgt_type))
  for item in matched_data:
    print('    .value("{}", {}::{})'.format(
      item['en_item'], tgt_type, item['en_item']))
  print('    ;')
  print('#endif //D_GENERATE_SOC_ENUMS')


import re

def common_matcher(line, prefix):
  m = re.match(r'\s+localparam\s+(\w+)\s*=\s*(\d+);', line)
  if m == None:
    return None

  en_item = m.group(1)
  if not en_item.startswith(prefix):
    return None

  en_item = en_item[len(prefix):]
  item_val = m.group(2)
  return { 'en_item': en_item, 'item_val': item_val }

gen_enum('en_state', 'rtl/cpu/cpu.v',
        lambda l: common_matcher(l, 'STATE_') )


