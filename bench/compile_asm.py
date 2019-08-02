import sys
import argparse
import os
import shutil
import subprocess



class CompileAsm:
    def __init__(self):
        self._parser = argparse.ArgumentParser(description='Converter from asm to hex for RISC-V security contest')
        self._parser.add_argument('--toolchain', dest='toolchain', default=None, help='Name for cross-toolchain')
        self._parser.add_argument('--input', dest='input_asm', default=None, help='Path to asm file to compile')
        self._parser.add_argument('--output-dir', dest='output_dir', default=None, help='Output di for resulted hex files')
        self._parser.add_argument('--linker', dest='linker_script', default=None, help='Path to linker script')
        self._parser.add_argument('--tmp-dir', dest='tmp_dir', default=None, help='Path for temp dir')
        self._args = self._parser.parse_args()

        if self._args.toolchain is None:
            print("You have to set --toolchain option")
            self._parser.print_help(sys.stderr)
            sys.exit(1)
        
        if self._args.input_asm is None:
            print("You have to set --input option")
            self._parser.print_help(sys.stderr)
            sys.exit(1)
        
        if self._args.output_dir is None:
            print("You have to set --output-dir option")
            self._parser.print_help(sys.stderr)
            sys.exit(1)
        
        if self._args.linker_script is None:
            print("You have to set --linker option")
            self._parser.print_help(sys.stderr)
            sys.exit(1)
        
        if self._args.tmp_dir is None:
            print("You have to set --tmp-dir option")
            self._parser.print_help(sys.stderr)
            sys.exit(1)

        self._compiler = self._args.toolchain + 'gcc'
        self._compiler_path = shutil.which(self._compiler)
        self._objcopy = self._args.toolchain + 'objcopy'
        self._objcopy_path = shutil.which(self._objcopy)
        self._input_asm_file = os.path.basename(self._args.input_asm)
        self._input_file_name = os.path.splitext(self._input_asm_file)[0]
        self._output_file = self._args.output_dir + '/' + self._input_file_name + '.hex'
        self._tmp_elf = self._args.tmp_dir + '/' + self._input_file_name + '.elf'
        self._tmp_bin = self._args.tmp_dir + '/' + self._input_file_name
        self._linker_script = self._args.linker_script

        self.__check_files()

    def __check_files(self):
        #check for toolchain
        if not self._compiler_path:
            print("Toolchain you specified doesn't exist: {0}".format(self._compiler))
            self._parser.print_help(sys.stderr)
            sys.exit(1)

        if not self._objcopy_path:
            print("Toolchain you specified doesn't exist: {0}".format(self._compiler))
            self._parser.print_help(sys.stderr)
            sys.exit(1)

        #check for output dir
        if not os.path.isdir(self._args.output_dir):
            print("Output directory you specified doesn't exist: {0}".format(self._args.output_dir))
            self._parser.print_help(sys.stderr)
            sys.exit(1)
        
        #check for tmp dir
        if not os.path.isdir(self._args.tmp_dir):
            print("Tmp directory you specified doesn't exist: {0}".format(self._args.tmp_dir))
            self._parser.print_help(sys.stderr)
            sys.exit(1)
        
        #check for input file
        if not os.path.exists(self._args.input_asm):
            print("Input asm file you specified doesn't exist: {0}".format(self._args.input_asm))
            self._parser.print_help(sys.stderr)
            sys.exit(1)
        
        #check for linker
        if not os.path.exists(self._linker_script):
            print("Linker script you specified doesn't exist: {0}".format(self._linker_script))
            self._parser.print_help(sys.stderr)
            sys.exit(1)

    def __make_asm_to_elf(self):
        cmd = [self._compiler_path, "-nostartfiles", "-march=rv32imc",  "-mabi=ilp32", "-T", self._linker_script, self._args.input_asm, "-o", self._tmp_elf] 
        p = subprocess.run(cmd)
        if p.returncode:
            print('Failed to execute command: "{0}"'.format(' '.join(cmd)))
            sys.exit(1)

    def __make_elf_to_bin(self):
        cmd = [self._objcopy_path, "-O", "binary", self._tmp_elf, self._tmp_bin] 
        p = subprocess.run(cmd)
        if p.returncode:
            print('Failed to execute command: "{0}"'.format(' '.join(cmd)))
            sys.exit(1)

    def __make_bin_to_hex(self):
        self._bin_data = open(self._tmp_bin, "rb").read()
        num_words = len(self._bin_data) // 4
        out_file = open(self._output_file, 'w')
        for i in range(num_words):
            w = self._bin_data[4*i : 4*i+4]
            out_file.write("%02x%02x%02x%02x\n" % (w[3], w[2], w[1], w[0]))
        out_file.close()

    def __cleanup(self):
        os.remove(self._tmp_bin)
        os.remove(self._tmp_elf)

    def convert(self):
        self.__make_asm_to_elf()
        self.__make_elf_to_bin()
        self.__make_bin_to_hex()
        self.__cleanup()

comp = CompileAsm()
comp.convert()
