#! /bin/csh

# You cannot make this script executable, you must run it using source:
#   $> source tools_setup.csh
# So that the environment variables remain set from the parent shell.
# Ensure your parent shell is csh or else this won't work.

set sourced=($_)
if ("$sourced" == "") then
  echo "FATAL: Must source this script (source tools_setup.csh), not execute it (./tools_setup.csh)"
  exit 1
endif

# Point to the root of this submodule repo
set SCRIPT_FULL=`echo $sourced | sed 's/source //'`
set SCRIPT_PATH=`dirname $SCRIPT_FULL`
setenv UVMA_AGENT_ROOT_PATH `realpath $SCRIPT_PATH/uvma-agents`

### Required simulation tools
#
# This script does not configure any modulefiles - set up your own
# site's environment for each of the following tools before running any
# simulation targets in cpm6/sim/Makefile, matching (or compatible with)
# the versions this testbench was validated against:
#
#   - Avery PCIe/CXL VIP and PLI, version 2025.3_1
#       Set AVERY_PLI to your installed PLI package path, e.g.
#       <install_root>/avery_pli-2025.3_1
#   - Synopsys VCS, version 2025.06-SP2-3
#       Set VCS_HOME to your VCS installation
#   - Synopsys Verdi, version 2025.06-SP2-2
#   - Siemens (Mentor) QuestaSim, version 2025.3
#       Set QUESTA_HOME to your QuestaSim installation and add its
#       bin directory to PATH
#
# Consult each tool vendor for licensing and installation instructions.
