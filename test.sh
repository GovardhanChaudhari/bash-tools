#!/bin/bash
set -o nounset    # Exposes unset variables
clear
# define a dictionary variable commands
declare -A commands

#commands[is]='source ./bash_aliases.txt'
commands[gs]='git status'
commands[gc]='git commit -m $1'

#echo ${!commands[@]}

for key in "${!commands[@]}"; do
  alias "$key"="${commands[$key]}"
  echo "${commands[$key]}"
done

source "$0"
gc