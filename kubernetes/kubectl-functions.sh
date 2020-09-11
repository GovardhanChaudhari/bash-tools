#!/bin/bash
kubectl_command="kubectl"
kubectl_get_command="$kubectl_command get"
kubectl_config_command="$kubectl_command config"
kubectl_port_forward_command="$kubectl_command port-forward"

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

# Launch dashboard
gkdb(){
    $kubectl_command proxy
}

#Launch weav dashboard
gkwd(){
    $kubectl_port_forward_command -n weave "$($kubectl_get_command -n weave pod --selector=weave-scope-component=app -o jsonpath='{.items..metadata.name}')" 4040
}