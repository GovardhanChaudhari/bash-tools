#base command
gdckr(){
docker $@
}

# docker images
gdckri(){
	gdckr images
}

# docker run 
gdckrrit(){
	gdckr run -it $@
}

# ps
gdckrps(){
	gdckr ps
}

# stop
gdckrstp(){
	gdckr stop $@
}

