isCommandExist(){
    if ! command -v $1 &> /dev/null
    then
        echo "COMMAND could not be found"
    else
        echo "Command exists"    
    fi
}