#!/bin/bash
# ============================================================================
# update_pipesim.sh  (common for CPM4 + CPM5)
# Pre-compile script for ALL simulation tools
#             (Xcelium, Questa, VCS, XSim).
# Reads C_CPM_PIPESIM from regenerated EP IP (.gen) and updates board.v.
#
# Location : <project>.sim/sim_1/behav/update_pipesim.sh
#            (parent of all simulator dirs: questa/ vcs/ xcelium/ xsim/)
#
# Called from pre_compile_hook.tcl via:
#   exec bash $update_sh
#
# Portable: works for CPM4 and CPM5, any user, any checkout path,
#           any project location. Uses 'find' to locate the CPM IP wrapper
#           so it is not sensitive to the per-BD hash in the filename.
# ============================================================================

# Auto-detect project root from this script's location
# Script is at: <proj_root>/<proj_name>.sim/sim_1/behav/update_pipesim.sh
# Navigate up 3 levels: behav/ → sim_1/ → <proj_name>.sim/ → <proj_root>/
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJ_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"   # 3 levels up from .sim/sim_1/behav/
PROJ_NAME="$(basename "$PROJ_ROOT")"              # e.g. CPM_QDMA_EP_SIM_design_xlm_25_001

echo "=== PIPESIM Auto-Update ==="
echo "Project root : $PROJ_ROOT"
echo "Project name : $PROJ_NAME"

# Path to board.v (user testbench — common for all simulators)
BOARD_V="$PROJ_ROOT/${PROJ_NAME}.srcs/sim_1/imports/sim_files/board.v"

# Locate the regenerated EP IP wrapper dynamically.
# The filename is bd_<hash>_cpm_0_0.sv where <hash> is generated per BD.
# Using 'find' makes this script hash-agnostic for CPM4 and CPM5.
# Search only the EP block design (cpm_qdma): .gen also contains the RP's
# bd_*_cpm_0_0.sv (design_rp), which can carry a different C_CPM_PIPESIM.
BD_CPM=$(find "$PROJ_ROOT/${PROJ_NAME}.gen" -path "*/bd/cpm_qdma/*/sim/bd_*_cpm_0_0.sv" 2>/dev/null | head -1)

# Validate files exist
if [ -z "$BD_CPM" ]; then
    echo "ERROR: EP IP file bd_*_cpm_0_0.sv not found under ${PROJ_NAME}.gen"
    exit 1
fi
if [ ! -f "$BOARD_V" ]; then
    echo "ERROR: board.v not found: $BOARD_V"
    exit 1
fi

echo "EP IP file   : $BD_CPM"

# Extract C_CPM_PIPESIM value from regenerated EP IP wrapper
PIPESIM_VAL=$(grep -o 'C_CPM_PIPESIM("[A-Z]*")' "$BD_CPM" | head -1 | grep -o '"[A-Z]*"' | tr -d '"')

if [ -z "$PIPESIM_VAL" ]; then
    echo "ERROR: Could not read C_CPM_PIPESIM from EP IP file"
    exit 1
fi

echo "Detected C_CPM_PIPESIM = \"$PIPESIM_VAL\" from EP IP (.gen)"

# Update board.v localparam PIPESIM (matches active non-commented line)
sed -i "s|localparam PIPESIM = \"[A-Z]*\";|localparam PIPESIM = \"${PIPESIM_VAL}\";|g" "$BOARD_V"

# Verify (exclude comment-only lines that start with //)
NEW_VAL=$(grep 'localparam PIPESIM = ' "$BOARD_V" | grep -v '^[[:space:]]*//' | grep -o '"[A-Z]*"' | head -1 | tr -d '"')
echo "board.v localparam PIPESIM updated to: \"$NEW_VAL\""

# Also sync .ip_user_files from .gen (in case export_ip_user_files left stale files)
IPU_CPM=$(echo "$BD_CPM" | sed "s|${PROJ_NAME}.gen|${PROJ_NAME}.ip_user_files|")
if [ -f "$BD_CPM" ] && [ -f "$IPU_CPM" ]; then
    cp "$BD_CPM" "$IPU_CPM"
    echo "Synced: $(basename "$BD_CPM") (.gen -> .ip_user_files)"
fi

echo "==========================="
