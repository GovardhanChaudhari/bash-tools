#!/bin/bash

isCommandExist(){
    if ! command -v "$1" &> /dev/null
    then
        echo false
    else
        echo true
    fi
}