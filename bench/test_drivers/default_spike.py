import subprocess
import os
import sys

import runner_checks as rchecks
import chores.pdeathsig

def run(libbench, opts, runner_override = None):
  tools = os.environ['DISTRIB_ROOT_DIR']
  spike_bin = os.path.join(tools, 'models/spike/bin/spike')

  print('running spike:')
  sim_args = [
      spike_bin,
      '-m0:256K',
      '--soc=beehive:uart_file=sim_uart.txt:id={}'.format(os.getcwd()),
      '--pc={}'.format(opts.spike_start_pc)
  ]
  if opts.dbg_enable_trace:
    sim_args.append('-l')
  sim_args.append(os.path.join(os.getcwd(), 'test.elf'))

  print(' '.join(sim_args))
  sim = subprocess.Popen(sim_args, preexec_fn = chores.pdeathsig.set_pdeathsig())
  sim.wait()

  tee = subprocess.Popen(["tee", "log.txt"], stdin=subprocess.PIPE)
  os.dup2(tee.stdin.fileno(), sys.stdout.fileno())
  os.dup2(tee.stdin.fileno(), sys.stderr.fileno())

  if sim.returncode == 0:
    print('Great Success')
  else:
    if (opts.expect_failure):
      print('Not-So-Great Success')
    else:
      raise Exception('miserable failure')

  print("Working directory: {}".format(os.getcwd()))
  rchecks.RunnerChecks().check_uart('sim_uart.txt')

