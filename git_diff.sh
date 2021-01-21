#! /bin/bash
# WORK IN PROGRESS
#
# Aim of this script:
#   Provide an easy way to get the git diff between two commit points
#.
# Note:.
#   Must be run in a git directory
#
# To do:
# .--------------------
# | Prettify our lovely output
# | Provide optargs/switch options
# |
#
# Done:
# .-------------------
# | Allow choice of how many commits previous (implemeted as $1)
# |

## Default variables
# Determine how many commit points to go back; default is 1
if [ "$1" == '' ]; then
  commit_count=1
else
  commit_count=$1
fi

total_count=0
git_log='/usr/bin/git log'
git_diff='/usr/bin/git diff'
## End of default variables

while read line; do
  if echo $line | grep '^commit '; then
    # assign first (i.e latest) commit point.
    if [ "$total_count" -eq "0" ]; then
      new_commit_number=$(echo $line | awk '{ print substr($2,1,8) }')
    # will only assign this variable once the relevant commit point has been reached
    elif [ "$total_count" -eq "$commit_count" ]; then
      old_commit_number=$(echo $line | awk '{ print substr($2,1,8) }')
      break
    fi
    total_count=$(($total_count + 1))
  fi
done < <($git_log)

$git_diff $old_commit_number $new_commit_number

