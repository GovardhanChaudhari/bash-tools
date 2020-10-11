#!/bin/bash

isCommandExist(){
    if ! command -v "$1" &> /dev/null
    then
        echo false
    else
        echo true
    fi
}

getLastArgument(){
    echo ${@:(-1)}
}

firstN(){
    local firstNParameters=$1
    local startFromIndex=2
    # Here @ indicates all params starting from first and not from zero
    echo "${@:startFromIndex:firstNParameters}"
}

getArgsExceptLast(){
   numberOfArgsMinusOne=$(($#-1))
   firstN $numberOfArgsMinusOne $@
}
