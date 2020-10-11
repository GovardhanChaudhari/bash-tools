#!/bin/bash

if [[ $(isCommandExist "microk8s") -eq true ]];
then
    kubectl_command="microk8s.kubectl" 
else
    kubectl_command="kubectl"
fi

kubectl_get_command="$kubectl_command get"
kubectl_apply_command="$kubectl_command apply"
kubectl_delete_command="$kubectl_command delete --ignore-not-found -f "
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
    gkdbt
    $kubectl_command proxy &
    gkodb
}

#Open dashboard
gkodb(){
    xdg-open http://localhost:8001/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy/#/overview?namespace=default &
}

# Launch dashboard
gkga(){
    $kubectl_command get all
}

#Launch weav dashboard
gkwd(){
    $kubectl_port_forward_command -n weave "$($kubectl_get_command -n weave pod --selector=weave-scope-component=app -o jsonpath='{.items..metadata.name}')" 4040
}

#Print dashboard token
gkdbt(){
    local token=$($kubectl_get_command secret $($kubectl_get_command serviceaccount default -o jsonpath='{.secrets[0].name}') -o jsonpath='{.data.token}' | base64 --decode )
    echo $token | xsel -b
    echo "Copied token to clipboard"
}

gka(){
    local path=`getLastArgument $@`
    local allArgsExceptPath=`getArgsExceptLast $@`
    echo "$kubectl_apply_command $allArgsExceptPath -f $path"
    $kubectl_apply_command $allArgsExceptPath -f $path
}

gkd(){
    $kubectl_delete_command "$1"
}