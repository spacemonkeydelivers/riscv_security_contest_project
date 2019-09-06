#!/usr/bin/python3 env
import os

test_list = []

repository_path = ''
test_path = './tests/c/ripe'
test_path += '/cfg/'

techniques        = ['direct', 'indirect']
code_ptrs         = ['ret', 'funcptrstackvar', 'funcptrstackparam', 'funcptrheap', 'funcptrbss', 'funcptrdata', 'structfuncptrstack',
                     'structfuncptrheap', 'structfuncptrdata', 'structfuncptrbss', 'longjmpstackvar', 'longjmpstackparam',
                     'longjmpheap', 'longjmpdata', 'longjmpbss','bof', 'iof', 'leak'];
functions         = ['memcpy', 'strcpy', 'strncpy', 'sprintf', 'snprintf', 'strcat', 'strncat', 'sscanf', 'homebrew'];
locations         = ['stack','heap','bss','data'];
inject_params     = ['shellcode', 'returnintolibc', 'rop', 'dataonly'];


techniques_en     = ['DIRECT', 'INDIRECT']
code_ptrs_en      = ['RET_ADDR', 'FUNC_PTR_STACK_VAR', 'FUNC_PTR_STACK_PARAM', 'FUNC_PTR_HEAP', 'FUNC_PTR_BSS', 'FUNC_PTR_DATA', 'STRUCT_FUNC_PTR_STACK',
                    'STRUCT_FUNC_PTR_HEAP', 'STRUCT_FUNC_PTR_DATA', 'STRUCT_FUNC_PTR_BSS', 'LONGJMP_BUF_STACK_VAR', 'LONGJMP_BUF_STACK_PARAM', 
                    'LONGJMP_BUF_HEAP', 'LONGJMP_BUF_DATA', 'LONGJMP_BUF_BSS', 'VAR_BOF', 'VAR_IOF', 'VAR_LEAK']
functions_en      = ['MEMCPY', 'STRCPY', 'STRNCPY', 'SPRINTF', 'SNPRINTF', 'STRCAT', 'STRNCAT', 'SSCANF', 'HOMEBREW']
locations_en      = ['STACK', 'HEAP', 'BSS', 'DATA']
inject_params_en  = ['INJECTED_CODE_NO_NOP', 'RETURN_INTO_LIBC', 'RETURN_ORIENTED_PROGRAMMING', 'DATA_ONLY']

def generate_test(technique, code_ptr, func, location, attack):
    # Generating test name from parameters.
    test_name = 'c_ripe_'
    test_name += technique[0]  + '_'
    test_name += code_ptr[0]   + '_'
    test_name += func[0]       + '_'
    test_name += location[0]   + '_'
    test_name += attack[0]
    print ("Test name: {}".format(test_name))
    # Generating *.cfg file content.
    config_content = []
    config_content.append('--technique')
    config_content.append(technique[1])
    config_content.append('--code_ptr')
    config_content.append(code_ptr[1])
    config_content.append('--function')
    config_content.append(func[1])
    config_content.append('--location')
    config_content.append(location[1])
    config_content.append('--attack')
    config_content.append(attack[1])
    # Writing generated config to a respective folder
    with open(repository_path + test_path + test_name + '.cfg', 'w') as config_file:
        for each in config_content:
            config_file.write(each)
            config_file.write('\n')
    # Generating CTest string.
    test_string = 'test_add(' + test_name + ' --cmd="' + test_path + test_name + '.cfg' + '" NIGHTLY WARN_DISABLE INVERT_RESULT)'
    test_list.append(test_string)

techniques      = list(zip(techniques, techniques_en))
code_ptrs       = list(zip(code_ptrs, code_ptrs_en))
functions       = list(zip(functions, functions_en))
locations       = list(zip(locations, locations_en))
inject_params   = list(zip(inject_params, inject_params_en))

if os.path.exists(repository_path + test_path):
    print("Path exists")
else:
    print(repository_path + test_path)
    os.makedirs(repository_path + test_path)
    print("Path does not exist, being created")

for tech in techniques[0:2]:
    for ptr in code_ptrs[0:2]:
        for func in functions[0:2]:
            for loc in locations[0:2]:
                for param in inject_params[0:2]:
                    generate_test(tech, ptr, func, loc, param)
with open('TestLists.txt', 'w') as tests_file:
    for each in test_list:
        tests_file.write(each)
        tests_file.write('\n')

