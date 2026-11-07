#!/usr/bin/env python3
import re
import sys

warns=-1
errors=-1
fatals=-1

if (len(sys.argv) < 2):
  sys.exit("ERROR: Must pass in filename to script")
elif (sys.argv[1] == 'simv.log'):
  pfx = '^'
else:
  pfx = '^# '

with open(sys.argv[1], 'r') as f:
  for line in f:
    match = re.search(r'{}UVM_WARNING :\s+(\d+)'.format(pfx), line)
    if match :
      warns = match.group(1)
    match = re.search(r'{}UVM_ERROR :\s+(\d+)'.format(pfx), line)
    if match :
      errors = match.group(1)
    match = re.search(r'^{}UVM_FATAL :\s+(\d+)'.format(pfx), line)
    if match :
      fatals = match.group(1)

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
