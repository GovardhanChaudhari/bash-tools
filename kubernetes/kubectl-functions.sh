#!/bin/bash
kubectl_command="kubectl"
kubectl_get_command="$kubectl_command get"
kubectl_apply_command="$kubectl_command apply -f"
kubectl_delete_command="$kubectl_command delete -f"
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

#Print dashboard token
gkdbt(){
    local token=$($kubectl_get_command secret $($kubectl_get_command serviceaccount default -o jsonpath='{.secrets[0].name}') -o jsonpath='{.data.token}' | base64 --decode )
    echo $token
}

gka(){
    $kubectl_apply_command "$1"
}

gkd(){
    $kubectl_delete_command "$1"
}