#! /usr/bin/bash

# Waits for an LSF job to finish and reports whether it succeeded.
#
# Argument 1: JOBID
# Argument 2: MAX TIME THE JOB MAY SIT IN PEND, IN SEC (opt., default 180)
# Argument 3: MAX TIMEOUT IN SEC (opt., default 3600)
#
# An empty argument ("") selects that argument's default, so the max timeout
# can be given without overriding the pending timeout.
#
# Exit codes:
#   0 - job finished in state DONE
#   1 - job finished in state EXIT (command failed or job was killed)
#   2 - job was still PEND after the pending timeout (job is killed)
#   3 - job hit the max timeout (job is killed)
#   4 - job could not be found
#   5 - bad arguments

JOBID=$1
PEND_TIMEOUT=${2:-180}
RUN_TIMEOUT=${3:-3600}

if ! [[ $JOBID =~ ^[0-9]+$ ]]; then
  echo "FATAL: Invalid LSF job ID '$JOBID'"
  exit 5
fi
if ! [[ $PEND_TIMEOUT =~ ^[0-9]+$ ]] || ! [[ $RUN_TIMEOUT =~ ^[0-9]+$ ]]; then
  echo "FATAL: Timeouts must be integers (pending='$PEND_TIMEOUT' max='$RUN_TIMEOUT')"
  exit 5
fi

# Number of consecutive failed status reads before declaring the job lost
MAX_MISSES=15
MISSES=0

TIME=0
H=0
M=0
S=0
while : ; do
  STS=$(bjobs $JOBID -noheader 2>/dev/null | awk 'NR==1 {print $3}')

  case $STS in
    DONE)
      printf "%1d:%02d:%02d | JOB %d STATUS: %s\n" $H $M $S $JOBID $STS
      exit 0
      ;;
    EXIT)
      printf "%1d:%02d:%02d | JOB %d STATUS: %s\n" $H $M $S $JOBID $STS
      exit 1
      ;;
    PEND|PSUSP|RUN|USUSP|SSUSP|UNKWN|ZOMBI|WAIT|PROV)
      MISSES=0
      ;;
    *)
      # bjobs gave nothing usable; LSF may be briefly unresponsive
      MISSES=$((MISSES+1))
      if [[ $MISSES -ge $MAX_MISSES ]]; then
        echo "FATAL: Could not find job $JOBID"
        exit 4
      fi
      ;;
  esac

  if [[ $STS == "PEND" && $TIME -ge $PEND_TIMEOUT ]]; then
    printf "%1d:%02d:%02d | JOB %d STATUS: %s\n" $H $M $S $JOBID $STS
    echo "FATAL: JOB $JOBID STILL PENDING AFTER $PEND_TIMEOUT SECONDS, KILLING IT"
    bjobs -p $JOBID 2>/dev/null | sed -n '1,10p'
    bkill $JOBID > /dev/null 2>&1
    exit 2
  fi

  if [[ $TIME -ge $RUN_TIMEOUT ]]; then
    printf "%1d:%02d:%02d | JOB %d STATUS: %s\n" $H $M $S $JOBID $STS
    echo "FATAL: JOB $JOBID HIT TIMEOUT $RUN_TIMEOUT SECONDS, KILLING IT"
    bkill $JOBID > /dev/null 2>&1
    exit 3
  fi

  # 10 seconds up to 1 minute
  if [[ $H -eq 0 && $M -eq 0 && $(( $S % 10 )) -eq 0 ]]; then
    printf "%1d:%02d:%02d | JOB %d STATUS: %s\n" $H $M $S $JOBID $STS
  # 1 minute up to 5 minutes
  elif [[ $H -eq 0 && $M -le 5 && $S -eq 0 ]]; then
    printf "%1d:%02d:%02d | JOB %d STATUS: %s\n" $H $M $S $JOBID $STS
  # 10 minutes up to 1 hour
  elif [[ $H -eq 0 && $(( $M % 10 )) -eq 0 && $S -eq 0 ]]; then
    printf "%1d:%02d:%02d | JOB %d STATUS: %s\n" $H $M $S $JOBID $STS
  # 15 minutes beyond 1 hour
  elif [[ $H -ne 0 && $(( $M % 15 )) -eq 0 && $S -eq 0 ]]; then
    printf "%1d:%02d:%02d | JOB %d STATUS: %s\n" $H $M $S $JOBID $STS
  fi

  sleep 1
  # Running count in seconds
  TIME=$((TIME+1))
  # Running count in H:M:S
  H=$(( $TIME/3600 ))
  M=$(( ( $TIME - $H * 3600 ) / 60 ))
  S=$(( $TIME - $H * 3600 - $M * 60 ))
done
