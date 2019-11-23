import signal
from ctypes import cdll

def set_pdeathsig(sig = signal.SIGHUP):
  def callable():
    print "OS WARNING: setting PR_SET_PDEATHSIG with signal = {}".format(sig)
    PR_SET_PDEATHSIG = 1
    return cdll['libc.so.6'].prctl(PR_SET_PDEATHSIG, sig)
  return callable
