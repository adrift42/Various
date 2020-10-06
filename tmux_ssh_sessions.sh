#!/bin/bash

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
    tmux new-session -d -s $sess "ssh $p"
  else
    tmux split-window -h "ssh $p"
    tmux select-layout tiled
  fi
  count=$((count+1))
done < $server_file

tmux attach -t $sess
