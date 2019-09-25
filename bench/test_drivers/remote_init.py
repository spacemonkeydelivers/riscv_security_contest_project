#!/usr/bin/python
import sys
import getopt
import json
import os
import shutil
import getpass
import json

try:
    import paramiko
except Exception as e:
    print '[-] Unexpected problem with importing <paramiko> module'
    print '[!] Consider installing it with \'pip install --user paramiko\''
    raise RuntimeError('coild not load required modules')

try:
    from scp import SCPClient
except Exception as e:
    print '[-] Unexpected problem with importing <scp> module'
    print '[!] Consider installing it with \'pip install --user scp\''
    raise RuntimeError('coild not load required modules')


# Global variables used for instruction refinary.
fpga_info_data = {}

# SESURITY! Expected file format:
#{ "user": "username", "password": "password", "host": "ip/hostname" }
with open(os.path.expanduser('~/.fpga_cfg.json')) as json_file:
   FPGA_REMOTE = json.load(json_file)

FPGA_TOOLS_ROOT = os.getenv('RISCV_FPGA_TOOLS_ROOT', '/mnt/fpga_tools')
WORKING_DIR_REMOTE = os.getenv('RISCV_REMOTE_ROOT', '/root')
username = getpass.getuser()
WORKING_DIR = os.path.join(WORKING_DIR_REMOTE, '.fpga_{}'.format(username))

# Constants for correct run of script.
TEST_STATUS = "test_status" # A110A110 ???? success
TEST_EXIT = "test_exit" # BADDAD if finished, DEADBABE if still kicking

# Reading fpga.info file, that should contain info on test results placement.
# TODO: not implemented
def read_fpga_info(test_directory):
    try:
        with open( TEST_DIRECTORY + TEST_NAME + '/fpga.info', 'r' ) as fpga_info:
            for string in fpga_info:
                fpga_info_data = json.loads(string)
    except Exception as e:
        print "[-] Could not read data from fpga.info file. Check TEST_DIRECTORY variable or content of fpga.info."
    print "[+] fpga.info for test is opened"
    print "[+] {} is located at {}".format(TEST_STATUS, fpga_info_data[TEST_STATUS])
    print "[+] {} is located at {}".format(TEST_EXIT, fpga_info_data[TEST_EXIT])
    return fpga_info_data

def ssh_connect():
    client = paramiko.SSHClient()
    hostname = FPGA_REMOTE['host']

    try:
        client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        client.connect(
            hostname = FPGA_REMOTE['host'],
            username = FPGA_REMOTE['user'],
            password = FPGA_REMOTE['password'])

        print "[+] Successfuly connected to host \'{}\' via ssh.".format(hostname)
    except Exception as e:
        print "[-] Could not connect to remote host {}".format(hostname)

    return client

# function to upload files over ssh/scp
def remote_upload(src, dst, directory = False):
    client = ssh_connect()
    print('scp {} -> remote: {}'.format(src, dst));
    with SCPClient(client.get_transport()) as scp:
        if directory:
            scp.put(src, recursive= True, remote_path = dst)
        else:
            scp.put(src, remote_path = dst)

# Fucntion to run instruction on remote server via SSH.
def remote_run(command, ignore_failures = False):
    client = ssh_connect()

    print "[+] Going to perform \'{}\' command".format(command)
    ret_code = -1
    try:
        stdin, stdout, stderr = client.exec_command(command)

        for line in stdout:
            print(line.strip('\n'))

        for line in stderr:
            print(line.strip('\n'))

        ret_code = stdout.channel.recv_exit_status()

        if ret_code == 0:
          print('[+] Great Success')
        else:
          print('[-] Miserable Failure')
        print('')

    except Exception as e:
        print '[-] Could not execute remote command <{}>'.format(e)

    client.close()

    if (ignore_failures == False) and (ret_code != 0):
        raise RuntimeError("remote run failed")

    return ret_code == 0


def copy_test_verilog(test_directory, mount_directory):
    if not os.path.exists(test_directory):
        print "[-] '{}' does not exist".format(test_directory)
        return False
    if not os.path.exists(mount_directory):
        print "[-] {} does not exist".format(mount_directory)
        return False
    print "[+] Both provided test and mount directory exists. Copying verilog test file to remote server"
    try:
        shutil.copyfile(test_directory + '/test.v', mount_directory + '/test.v')
    except Exception as e:
        print "[-] Troubles with copying, shady shit going on."

def run_ctest(build_directory, test_name):
    print '[*] Trying to run test ' + test_name
    os.system('cd ' + build_directory + ';' + 'ctest -R ' + test_name)
    if os.path.isdir(build_directory + '/tests/' + test_name):
        print "[+] According to created directory {}, test ran successfully".format(test_name)
    else:
        assert False, "What the hell is this"

def run(libbench):
    INPUT_FILE = sys.argv[2]
    if not os.path.isfile(INPUT_FILE):
        print 'could not detect input file <{}>'.format(INPUT_FILE)
        raise RuntimeError('missing input file')

    print 'Assessing environment...'
    bin_tools = [
        'fpga_loader',
        'fpga_reader',
        'fpga_reset',
        'fpga_writer'
    ]
    paths = {}
    tools_list = []
    for item in bin_tools:
        tool_path = os.path.join(FPGA_TOOLS_ROOT, 'bin', item)
        paths[item] = tool_path
        tools_list.append(tool_path)
    test_cmd = 'test -f ' + ' -a -f '.join(["'{}'".format(i) for i in tools_list])
    remote_run(test_cmd)

    REMOTE_LIB = os.path.join(FPGA_TOOLS_ROOT, 'lib', 'libbench.so')
    libtest_cmd = 'test -f \'{}\''.format(REMOTE_LIB)
    remote_run(libtest_cmd)

    print 'Prepairing workspace'
    workspace_probe = os.path.join(WORKING_DIR, '.fuck_me')
    probe_cmd = 'test -f \'{}\''.format(workspace_probe)
    status = remote_run(probe_cmd, ignore_failures = True)
    if status == True:
      # initiate cleanup activities
      remote_run('rm -rf \'{}\''.format(WORKING_DIR))

    create_commands = [
      'mkdir \'{}\''.format(WORKING_DIR),
      'touch \'{}/.fuck_me\''.format(WORKING_DIR),
      'cp \'{}\' \'{}\''.format(REMOTE_LIB, WORKING_DIR)
    ]
    remote_run(' && '.join(create_commands))

    DIR_TESTBENCH = os.environ['TESTBENCH_DIR']
    WRAPPER = os.path.join(DIR_TESTBENCH, 'emulation/dut_wrapper')
    LIBS = os.path.join(DIR_TESTBENCH, 'test_drivers/benchlibs')
    DRIVER = os.path.join(DIR_TESTBENCH, 'test_drivers/default_fpga.py')
    remote_upload(WRAPPER, WORKING_DIR, directory = True)
    remote_upload(LIBS, WORKING_DIR, directory = True)
    remote_upload(DRIVER, WORKING_DIR)

    remote_upload(INPUT_FILE, os.path.join(WORKING_DIR, 'test.v'))

    bitstream_path = os.path.join(os.environ['FPGA_FILES'], 'fpga.bit')
    print 'copying bitstream...'
    if not os.path.isfile(bitstream_path):
        print 'could not detect bitstream! make sure that you have one'
        raise RuntimeError("missing bitstream")
    remote_upload(bitstream_path, WORKING_DIR)

    print 'uploading bitstream on emulator'
    remote_run('{} /dev/fpga \'{}\''.format(paths['fpga_loader'],
                                  os.path.join(WORKING_DIR, 'fpga.bit')))
    print "run!"
    remote_run('/usr/bin/python2 {} {}'.format(
          os.path.join(WORKING_DIR, 'default_fpga.py'),
          os.path.join(WORKING_DIR, 'test.v')));

