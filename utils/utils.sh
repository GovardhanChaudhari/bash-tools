#!/bin/bash

# Reload bash-tools aliases and functions
gbtr(){
    source $GVC_BASH_TOOLS_HOME/index.sh
    echo "gvc-tools reloaded"
}

# Go to bash-tools dir
gbtd(){
    cd $GVC_BASH_TOOLS_HOME
}
