#! /bin/bash

# You cannot make this script executable, you must run it using source:
#   $> source tools_setup.bash
# So that the environment variables remain set from the parent shell.
# Ensure your parent shell is bash or else this won't work.

(return 0) 2>/dev/null && sourced=1 || sourced=0
if [ $sourced -ne 1 ]; then
  echo "FATAL: Must source this script (source tools_setup.bash), not execute it (./tools_setup.bash)"
  exit 1
fi

# Point to the root of this submodule repo
SCRIPT_PATH=$(dirname -- ${BASH_SOURCE[0]})
export UVMA_AGENT_ROOT_PATH=`realpath $SCRIPT_PATH/uvma-agents`

# Remove excluded arguments from input
args_exclude=("autolist")
filtered_args=()
for arg in "$@"; do
  exclude=0
  for excl in "${args_exclude[@]}"; do
    if [[ "$arg" == "$excl" ]]; then
      exclude=1
      break
    fi
  done
  if [[ $exclude -eq 0 ]]; then
    filtered_args+=("$arg")
  fi
done
set -- "${filtered_args[@]}"

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
