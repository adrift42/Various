#! /bin/bash
#
#
#
# This script initialises yum-cron based upon the /etc/yum/yum-cron.conf
# settings and will be called through cronjob yum_monthly_update_schedule
# and if /usr/sbin/yum-cron completes with a successful exit code (0) the
# server will be rebooted

# Define temp file for Nagios to check and alert upon
# DO NOT use variables within this variable - there is a scripted rm -f against
# this file path and if a variable is used that is empty, accidental file deletion may occur
NAGIOS_WARNING_FILE="/tmp/patching_state.tmp"

# Define log file for yum notifications
PATCHING_LOG_FILE="/var/log/patching_log.log"

# Obtain current time & date
PATCHING_DATE=${date +%d-%m-%Y_%H:%M}

# Create Nagios warning file - if patching goes without errors this file will.
# be removed before server reboot, else requires sysadmin to remove when errors resolved
touch $NAGIOS_WARNING_FILE && chmod 0700 $NAGIOS_WARNING_FILE

# Create log file tracking the patching start time & date
echo "$PATCHING_DATE : Automatic patching has begun" >> $PATCHING_LOG_FILE

# Set variable defaults; 0 = true, 1 = false
RUN_BY_CRON=1
DO_WE_RESTART=0

# Define variables based upon switch statements used;
# -a disables automatic reboot, -c states cron is script executor, -m disables patching altogether, 
# -s adds a pre-patching script to be run, -S adds a post-patching script to be run, -F adds a post-patching script to be run if patching fails

while getopts 'acms:S:F:' OPTION; do
  case "$OPTION" in
    a)
      DO_WE_RESTART=1
      echo "WARN: REQUIRES MANUAL REBOOT" > $NAGIOS_WARNING_FILE
      ;;
    c)
      RUN_BY_CRON=0
      ;;
    m)
      echo "CRIT: AUTOMATIC PATCHING DISABLED; REQUIRES MANUAL PATCHING" > $NAGIOS_WARNING_FILE
      cat $NAGIOS_WARNING_FILE >> $PATCHING_LOG_FILE
      exit 1
      ;;
    s)
      PRE_SCRIPT_PATH=$OPTARG
      echo "Additional script $PRE_SCRIPT_PATH will be run prior to patching" >> $PATCHING_LOG_FILE
      ;;
    S)
      POST_SCRIPT_PATH=$OPTARG
      echo "Additional script $POST_SCRIPT_PATH will be run before reboot if patching completes successfully" >> $PATCHING_LOG_FILE
      ;;
    F)
      FAILED_SCRIPT_PATH=$OPTARG
      echo "Additional script $FAILED_SCRIPT_PATH will be run before reboot if patching does not exit successfully" >> $PATCHING_LOG_FILE
      ;;
    ?)
      echo "CRIT: PATCHING ABORTED - CRONJOB CONTAINS ARG ERRORS" > $NAGIOS_WARNING_FILE
      cat $NAGIOS_WARNING_FILE >> $PATCHING_LOG_FILE
      exit 1
      ;;
  esac
done

# Cron is set to run this script with the -c switch in an attempt to prevent
# unwanted and unexpected server reboots if someone manually runs this script.
# If no -c switch is provided, this script will not update or reboot the server.

if [ $RUN_BY_CRON -eq 1 ]; then
  echo "*** This script should not be manually run - please use 'yum cleanall; yum makecache; yum upgrade' ***"
  echo "WARN: RUN_YUM.SH SCRIPT HAS BEEN EXECUTED MANUALLY - PATCHING NOT COMPLETED" >> $NAGIOS_WARNING_FILE
  cat $NAGIOS_WARNING_FILE >> $PATCHING_LOG_FILE
  exit 1
fi


#### PRE-PATCHING ####

if [ "$PRE_SCRIPT_PATH" ]; then
  echo "Running $PRE_SCRIPT_PATH now" >> $PATCHING_LOG_FILE
  $PRE_SCRIPT_PATH
fi


#### PATCHING RUN ####

/usr/sbin/yum-cron >> $PATCHING_LOG_FILE 2>&1
PATCHING_EXIT_STATE=$?


#### POST PATCHING ####

# if patching succeeds:
if [ $PATCHING_EXIT_STATE -eq 0 ]; then

  if [ "$POST_SCRIPT_PATH" ]; then
    echo "Running '$POST_SCRIPT_PATH' now" >> $PATCHING_LOG_FILE
    $POST_SCRIPT_PATH
  fi

  if [ $DO_WE_RESTART -eq 0 ]; then
    rm -f $NAGIOS_WARNING_FILE
    echo "REBOOTING SERVER NOW - NAGIOS WARNING FILE $NAGIOS_WARNING_FILE HAS BEEN REMOVED" >> $PATCHING_LOG_FILE
    /usr/sbin/reboot
  fi
# if patching fails:
else 
  echo "CRIT: PATCHING HAS FAILED - CHECK $PATCHING_LOG_FILE FOR POSSIBLE ERRORS" >> $NAGIOS_WARNING_FILE
  cat $NAGIOS_WARNING_FILE >> $PATCHING_LOG_FILE
fi

# if patching fails but failed-patching script should be actioned:
if [ $PATCHING_EXIT_STATE -ne 0 ] && [ "$FAILED_SCRIPT_PATH" ]; then
  echo "Patching has failed, however $FAILED_SCRIPT_PATH will still be run now" >> $PATCHING_LOG_FILE
  $FAILED_SCRIPT_PATH
fi
