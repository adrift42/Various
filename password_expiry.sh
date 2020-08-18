#!/bin/bash
# Script to list accounts, password expiry details, and last password changed date
for account in $(cut -f1 -d: /etc/passwd); do echo "ACCOUNT: $account , EXPIRES: `chage -l $account | grep 'Password expires' | awk '{print $4, $5, $6}'`, CHANGED: `chage -l $account | grep 'Last password change' | awk '{print $5, $6, $7}'`"; done
