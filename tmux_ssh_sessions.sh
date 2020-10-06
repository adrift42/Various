#!/bin/bash
#
# Author: 		adrift42
#
# Date created:		06/10/2020
#
# Description:		Load up a tmux session with a whole lot of panes automatically
#			sshing to a list of servers provided. Has a few options to customise.
#
# Options (required):	-f	takes a plaintext file with a list of servers (one per line). These
#				will be used to load up a tmux pane per server and kick off an ssh
#				connection
#			-s 	session name for tmux - needs to be unique if you have other tmux 
#				sessions running
# Options (optional):	-S	instead of the normal ssh command, adds on a keepalive argument if
#				you are expecting to be connected for a long time - prevents the ssh
#				connection from timing out. WARNING: can be considered not very 
#				security-conscious.
#
# Please offer any thoughts or additions either via issues or PRs
#

while getopts 'f:s:S' OPTION; do
  case "$OPTION" in
    s)	
      sess=$OPTARG
      echo "Session name is: ${sess}"
      ;;
    f)	
      server_file=$OPTARG
	  echo "Server list file is: $server_file"
      ;;
	S)
      ssh_command='ssh -o ServerAliveInterval=60'
	  echo "ssh command set to keep the connection alive. Are you sure this is what you want to do?"
      ;;
    ?)
      echo "You MUST supply a session name (-s sess_name) and a list of servers to ssh (-f /path/to/server_list.txt). E.g: ${0} -f /path/to/file.txt -s session_name"
	  echo 'Exiting now.'
      exit 1
      ;;
  esac
done

count=1

if [ ! -z "${ssh_command}" ]; then
	ssh_command='ssh'
fi

while read p; do
  if [ $count == 1 ]; then
    tmux new-session -d -s $sess "${ssh_command} ${p}"
  else
    tmux split-window -h "${ssh_command} ${p}"
    tmux select-layout tiled
  fi
  count=$((count+1))
done < $server_file

tmux attach -t $sess
