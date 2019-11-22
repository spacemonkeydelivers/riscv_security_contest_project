import os

class RunnerChecks():
  def __init__(self):
    pass

  def check_uart(self, uart_file):
    print 'RunnerChecks: searching for uart.expected file'
    if not os.path.isfile('uart.expected'):
      print 'RunnerChecks: uart.expected file is not found'
      return True

    check_cmd = ' && '.join(['cat {} | sed \'/^LIBC: /d\'>_io.txt'.format(uart_file),
                            'diff _io.txt uart.expected'])
    print 'uart.expected found, running check command'
    print 'check command: {}'.format(check_cmd)

    ret = os.system(check_cmd)
    if ret == 0:
      print('UART output matches the expected one')
    else:
      raise Exception('UART output mismatch!, test failed')

