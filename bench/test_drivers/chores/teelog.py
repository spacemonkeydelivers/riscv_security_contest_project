import sys

# When we have interactive debugging session we want to save the output
# to a log file. The TeeLog class is designed to do exactly that.
#
# To archive this goal, originally I used the following code:
#   tee = subprocess.Popen(["tee", "log.txt"], stdin=subprocess.PIPE)
#   os.dup2(tee.stdin.fileno(), sys.stdout.fileno())
#   os.dup2(tee.stdin.fileno(), sys.stderr.fileno())
# but for whatever reason it stopped working after OS update. The reason is
# an assert inside promt-toolkit
# (looks like https://github.com/prompt-toolkit/python-prompt-toolkit/issues/502)

# In despair I copy-pasted the code from stackoverflow. I don't really
# care why the code stopped working. The reason is simple - I hate python and
# want nothing to do with this abomination. I just want something which
# gets the job done - don't really care how it works.
#
# Courtesy to:
# John T: https://stackoverflow.com/questions/616645/how-to-duplicate-sys-stdout-to-a-log-file/3423392#3423392

class TeeLog(object):
   def __init__(self, name, mode):
     #unbuffered
     self.file = open(name, mode, 0)
     # self.file = None
     self.stdout = sys.stdout
     sys.stdout = self
   def close(self):
     if self.stdout is not None:
       sys.stdout = self.stdout
       self.stdout = None
     if self.file is not None:
       self.file.close()
       self.file = None
   def write(self, data):
     self.file.write(data)
     self.stdout.write(data)
   def flush(self):
     self.file.flush()
     self.stdout.flush()
   def __del__(self):
     self.close()

