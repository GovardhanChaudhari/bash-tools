#!/bin/bash

# Reload bash-tools aliases and functions
grt(){
    source $GVC_BASH_TOOLS_HOME/index.sh
    echo "gvc-tools reloaded"
}

# Go to bash-tools dir
gbd(){
    cd $GVC_BASH_TOOLS_HOME
}