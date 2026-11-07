#! /bin/bash
# DESCRIPTION
# The uvma-pcie-sim-framework uses this script when compiling a Vivado DUT
# and the DUT_CLIBS=MANY option has been specified to the Makefile during
# the "c compile" target's prerequisites are run. Summarizing, this script
# parses the COMPILE_FILE (likely compile.sh) and pulls out the different
# work libraries and associated files and incdirs.

# Grab file to parse 
COMPILE_FILE=$1; shift

# Grab simulator
SIM=$1; shift

# Constant commands to compile SV and VHDL
if [[ "$1" == "-sv" ]]; then
  PARSE=SV; shift
  CMD=$@
elif [[ "$1" == "-vhd" ]]; then
  PARSE=VHD; shift
  CMD=$@
else
  echo "FATAL: Third argument must be -sv or -vhd"
  exit 1
fi

# Set if -kdb is in command
if [[ "$CMD" =~ "-kdb" ]]; then
  KDB=1
else
  KDB=0
fi

# Set a single logfile, and the tool-invocation keyword to detect in
# COMPILE_FILE for this simulator/language (vcs emits one vlogan/vhdlan
# call per line in compile.sh; questa emits one vlog/vcom call per line
# in the Vivado-generated *_compile.do file, which compile.sh only calls)
if [[ "$SIM" == "vcs" ]]; then
  if [[ "$PARSE" == "SV" ]]; then
    TOOL_MATCH="vlogan "
    if [[ $KDB -eq 1 ]]; then
      LOGFILE=clibs/vlogan.vivado_dut_KDB.log
    else
      LOGFILE=clibs/vlogan.vivado_dut.log
    fi
  elif [[ "$PARSE" == "VHD" ]]; then
    TOOL_MATCH="vhdlan "
    if [[ $KDB -eq 1 ]]; then
      LOGFILE=clibs/vhdlan.vivado_dut_KDB.log
    else
      LOGFILE=clibs/vhdlan.vivado_dut.log
    fi
  fi
elif [[ "$SIM" == "questa" ]]; then
  if [[ "$PARSE" == "SV" ]]; then
    TOOL_MATCH="vlog "
    LOGFILE=clibs/vlog.vivado_dut.log
  elif [[ "$PARSE" == "VHD" ]]; then
    TOOL_MATCH="vcom "
    LOGFILE=clibs/vcom.vivado_dut.log
  fi
fi
# Create clibs dir if not present
if [[ ! -d clibs ]]; then
  mkdir clibs
else
  rm -f $LOGFILE
fi
# Create singular compilation logfile
touch $LOGFILE

# Variable to control extraction
GO=0

while IFS= read -r line; do
 # Detect start condition to extract some data
 if [[ "$PARSE" == "SV" && "$line" =~ "$TOOL_MATCH" && $(echo $line | grep -c "^#") -eq 0 ]]; then
   GO=1
   WORK=$(echo "$line" | grep -Eo '\-work [[:alnum:]_]+' | cut -d ' ' -f2)
   # Extract each "+incdir+..." token individually and strip any quotes.
   # Depending on the Vivado version, compile.sh emits these either quoted
   # ("+incdir+<path>") or bare (+incdir+<path>), so both forms must be
   # matched. Each token is matched separately rather than with one greedy
   # match spanning all of them, and $CMD ... $INCDIRS is unquoted anyway so
   # any retained quote characters would just be literal, unparsed data.
   INCDIRS=$(echo "$line" | grep -oE '"?\+incdir\+[^" ]*"?' | tr -d '"' | tr '\n' ' ')
   # Extract every "-L <library>" search-path flag on the trigger line.
   # Vivado adds these so the compiler can resolve packages/types defined
   # in other already-compiled libraries (e.g. cpm6_v1_0_8_pkg, needed by
   # cpm6_interface.svh) - dropping them causes "Could not find the
   # package" errors for any file that references such a package.
   LIBS=$(echo "$line" | grep -Eo '\-L [[:alnum:]_]+' | tr '\n' ' ')
   FILES=
 elif [[ "$PARSE" == "VHD" && "$line" =~ "$TOOL_MATCH" && $(echo $line | grep -c "^#") -eq 0 ]]; then
   GO=1
   WORK=$(echo "$line" | grep -Eo '\-work [[:alnum:]_]+' | cut -d ' ' -f2)
   LIBS=
   FILES=
   # vlogan (SystemVerilog) compilation will create the library if it doesn't
   # exist, but vhdlan (VHDL) compilation will fatal if it isn't present
   if [[ $KDB -eq 0 && ! -d clibs/vivado_dut/$WORK ]]; then
     mkdir clibs/vivado_dut/$WORK
   elif [[ $KDB -eq 1 && ! -d clibs/vivado_dut_KDB/$WORK ]]; then
     mkdir clibs/vivado_dut_KDB/$WORK
   fi
 fi
 # During go condition, pull out RTL files (string=^"<path>/<name>" OR ... "glbl.v").
 # Extract every quoted token on the line except "+incdir+..." ones (those
 # are handled separately above) - this correctly covers a file quoted
 # alongside the tool invocation on a single line (e.g. glbl.v) as well as
 # one-quoted-file-per-line continuations, without re-capturing incdirs.
 if [[ $GO -eq 1 ]]; then
   MOD_LINE=$(echo "$line" | grep -oE '"[^"]*"' | grep -v '^"+incdir+' | tr -d '"' | tr '\n' ' ')
   if [[ -n $MOD_LINE ]]; then
     FILES+="$MOD_LINE "
   fi
   # Stop condition: vcs's compile.sh terminates each invocation with a
   # "/dev/null" redirect line; questa's *_compile.do separates each
   # invocation with a blank line instead.
   if { [[ "$SIM" == "vcs" ]] && [[ "$line" =~ "/dev/null" ]]; } || \
      { [[ "$SIM" == "questa" ]] && [[ -z "$line" ]]; }; then
     # Remove string "$origin_dir/" 
     FILES=${FILES//\$origin_dir\//}
     INCDIRS=${INCDIRS//\$origin_dir\//}
     # Stop
     GO=0
     # Execute command
     $CMD -work $WORK $LIBS $FILES $INCDIRS -l .tmp_log
     # Copy each command output to logfile
     cat .tmp_log >> $LOGFILE
   fi
 fi
done < $COMPILE_FILE

# Remove the temp log file
rm -f .tmp_log

