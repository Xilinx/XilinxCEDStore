#!/usr/bin/env python3
# This script parses a simulation logfile and summarizes the run results.
#  arg1 : simulator
#  arg2 : simulation logfile absolute path (required)
#  arg3 : if given, then write results to this file (optional)
#  arg4 : if 1, write only logfile name to args, else write full path (optional)
import re
import sys
from os.path import basename,exists

uvm_warns=-1
uvm_errors=-1
uvm_fatals=-1
sv_warns=0
sv_errors=0
sv_fatals=0

if (len(sys.argv) < 3):
  sys.exit("ERROR: Must pass ARG1=simulator and ARG2=filename to script")
else:
  if (sys.argv[1]=='vcs'):
    uvm_pfx = '^'
    sv_pfx  = '^'
    sim = 'vcs'
  elif (sys.argv[1]=='questa'):
    uvm_pfx = '^# '
    sv_pfx  = '^# \*\* '
    sim = 'questa'
  else:
    sys.exit('ERROR: Simulator \'{}\' is invalid'.format(sys.argv[1]))

if not exists(sys.argv[2]):
  sys.exit('ERROR: File \'{}\' given to search does not exist'.format(sys.argv[2]))
else:
  logfile=sys.argv[2]

summary_hit=0
with open(logfile, 'r') as f:
  for line in f:
    # This block catches UVM reporting: `uvm_info, `uvm_warning, etc.
    if (re.search('Report counts by severity', line) is not None) :
      summary_hit=1
    if (re.search('Report counts by id', line) is not None) :
      summary_hit=2
    if summary_hit==1 :
      match = re.search(r'{}UVM_WARNING :\s*(\d+)'.format(uvm_pfx), line)
      if match :
        uvm_warns = int(match.group(1))
      match = re.search(r'{}UVM_ERROR :\s*(\d+)'.format(uvm_pfx), line)
      if match :
        uvm_errors = int(match.group(1))
      match = re.search(r'{}UVM_FATAL :\s*(\d+)'.format(uvm_pfx), line)
      if match :
        uvm_fatals = int(match.group(1))
    # This block catches SV built-ins: $error, $fatal, etc.
    if (sim=='vcs') :
      if (re.match(r'{}Warning: .* at time'.format(sv_pfx), line)): sv_warns += 1
      if (re.match(r'{}Error: .* at time'.format(sv_pfx), line)): sv_errors += 1
      if (re.match(r'{}Fatal: .* at time'.format(sv_pfx), line)): sv_fatals += 1
    elif (sim=='questa') :
      if (re.match(r'{}Warning:'.format(sv_pfx), line)): sv_warns += 1
      if (re.match(r'{}Error:'.format(sv_pfx), line)): sv_errors += 1
      if (re.match(r'{}Fatal:'.format(sv_pfx), line)): sv_fatals += 1

# Combine UVM report-catcher counts (uvm_*) with SV built-in $error/$fatal
# counts (sv_*). Keeping them separate while scanning means a 0 from one
# source can never silently clobber a nonzero count already tallied from
# the other, regardless of which one appears later in the log.
if uvm_warns==-1 and uvm_errors==-1 and uvm_fatals==-1 and sv_warns==0 and sv_errors==0 and sv_fatals==0 :
  warns  = -1
  errors = -1
  fatals = -1
else :
  warns  = sv_warns  + (uvm_warns  if uvm_warns  != -1 else 0)
  errors = sv_errors + (uvm_errors if uvm_errors != -1 else 0)
  fatals = sv_fatals + (uvm_fatals if uvm_fatals != -1 else 0)

# Print results to a file
if (len(sys.argv) >= 4):
  f = open(sys.argv[3], "a")
  if (len(sys.argv)==5 and int(sys.argv[4]) == 1):
    testname = basename(logfile)
  else:
    testname = logfile
  if int(fatals)==-1 and int(errors)==-1 and int(warns)==-1 :
    f.write(f'{testname} = ERROR OCCURED\n')
  elif int(fatals)==0 and int(errors)==0 and int(warns)==0 :
    f.write(f'{testname} = PASS\n')
  elif int(fatals)==0 and int(errors)==0 and int(warns)!=0 :
    f.write(f'{testname} = PASS WITH {warns} WARNINGS\n')
  elif int(fatals)!=0 :
    f.write(f'{testname} = FATAL\n')
  elif int(errors)!=0 :
    f.write(f'{testname} = FAIL WITH {errors} ERRORS\n')
  f.close()
# Print results to stdout
else:
  if int(fatals)==-1 and int(errors)==-1 and int(warns)==-1 :
    print("TEST RESULTS = \033[34mERROR OCCURED\033[0m")
  elif int(fatals)==0 and int(errors)==0 and int(warns)==0 :
    print("TEST RESULTS = \033[32;5mPASS\033[0m")
  elif int(fatals)==0 and int(errors)==0 and int(warns)!=0 :
    print("TEST RESULTS = \033[32;5mPASS WITH {} WARNINGS\033[0m".format(warns))
  elif int(errors)!=0 :
    print("TEST RESULTS = \033[31;5mFAIL WITH {} ERRORS\033[0m".format(errors))
  elif int(fatals)!=0 :
    print("TEST RESULTS = \033[31;5mFATAL\033[0m")
