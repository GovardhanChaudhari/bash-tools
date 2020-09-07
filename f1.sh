#!/bin/bash
source gvc-file-utils.txt
gc(){
    echo "$1"
}

gcp(){
   gc $*
}

#gcp "hi"
