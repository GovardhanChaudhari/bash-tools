#!/bin/bash
dest_dir="$HOME/bash-tools"
alia_file="bash_aliases.txt"
if [[ -d $dest_dir ]] ; then
  echo "Directory '$dest_dir' exists, skiping git clonning"
else
  git clone https://github.com/GovardhanChaudhari/bash-tools.git  "$dest_dir"
fi
final_path="$dest_dir/$alia_file"
echo $final_path
source $final_path