import sys
import getopt
import json
import os
import shutil
try:
    import paramiko
except Exception as e:
    print '[-] Unexpected problem with importing <paramiko> module'
    print '[!] Consider installing it with \'pip install --user paramiko\''

# Global variables used for instruction refinary.
fpga_info_data = {}

# Constants for correct run of script.
TEST_STATUS = "test_status" # A110A110 ???? success
TEST_EXIT = "test_exit" # BADDAD if finished, DEADBABE if still kicking
BUILD_DIRECTORY = '/tank/work/notmytempo/riscv_core/build'
TEST_DIRECTORY = BUILD_DIRECTORY + '/tests/' 
TEST_NAME = 'asm_cext_addi'#'asm_simple' #
MOUNT_DIRECTORY = '/tank/work/dev/nfs/at91/mnt/PUBLIC_ENEMY'

# Constants for remote server
REMOTE_DIRECTORY = '/mnt/PUBLIC_ENEMY/'

# Reading fpga.info file, that should contain info on test results placement.
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
    
# Fucntion to run instruction on remote server via SSH.
def connect_to_ssh(hostname, username, password, command):
    client = paramiko.SSHClient()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    try:
        client.connect(hostname = hostname, username = username, password = password)
        print "[+] Successfuly connected to host \'{}\' via ssh.".format(hostname)
        print "[+] Going to perform \'{}\' command".format(command)
        stdin, stdout, stderr = client.exec_command(command)
        for line in stdout:
            print(line.strip('\n'))
            client.close()
    except Exception as e:
        print "[-] Could not connect to remote host {}".format(host)

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

def main(argv):
    # Populating build directory and test name.
    build_dir = ''
    test_name = ''
    if not argv:
        assert False, "empty argument list"
    try:
        opts, args = getopt.getopt(argv,"hb:e",["build_dir=","test_name="])
    except getopt.GetoptError as e:
        print 'remote_testing.py --build_dir=<directory where the wild things are> --test_name<the actuall test name from TestList.txt>'
        sys.exit(2)
    for opt, arg in opts:
        if opt == '-h':
            print 'remote_testing.py --build_dir=<directory where the wild things are> --test_name<the actuall test name from TestList.txt>'
            sys.exit()
        elif opt in ("-b", "--build_dir"):
            build_dir = arg
        elif opt in ("-t", "--test_name"):
            test_name = arg
        else:
            assert False, "unhandled option"

    if build_dir =='' or test_name == '':
        print '[!] Some required arguments are empty!!'
        exit(2)

    run_ctest(BUILD_DIRECTORY, TEST_NAME)
    fpga_info_data = read_fpga_info(TEST_DIRECTORY + TEST_NAME)
    copy_test_verilog(TEST_DIRECTORY + TEST_NAME, MOUNT_DIRECTORY)
    executed_command = 'cd '
    executed_command += REMOTE_DIRECTORY
    executed_command += '; '
    executed_command += './fpga.py --status={} --exit={}'.format(fpga_info_data['test_status'], fpga_info_data['test_exit'])
    connect_to_ssh('192.168.230.19', 'root', 'root', executed_command)
    
if __name__ == '__main__':
    main(sys.argv[1:])
