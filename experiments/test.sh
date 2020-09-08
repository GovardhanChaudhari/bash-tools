#!/bin/bash
#set -o nounset    # Exposes unset variables
clear
# define a dictionary variable commands
declare -A commands

commands[gs]='git status'
#echo ${!commands[@]}

for key in "${!commands[@]}"; do
  alias "$key"="${commands[$key]}"
  echo "${commands[$key]}"
done