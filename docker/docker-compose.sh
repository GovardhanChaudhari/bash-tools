# base command
gdckrc(){
docker compose $@
}

# build
gdckrcb(){
gdckrc build $@
}

#up
gdckrcup(){
gdckrc up
}

# down
gdckrcdwn(){
gdckrc down
}
