#!/bin/bash
kubectl_command="kubectl"
kubectl_get_command="$kubectl_command get"
kubectl_config_command="$kubectl_command config"

#List namespaces
gkln(){
    $kubectl_get_command namespaces
}

# List pods
gklp(){
    $kubectl_get_command pods
}

#Set current namespace
gkscn(){
    export CONTEXT=$($kubectl_config_command view | awk '/current-context/ {print $2}')
    $kubectl_config_command set-context $CONTEXT --namespace="$1"
}
