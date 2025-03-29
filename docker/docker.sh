# Base docker command
# Usage: gdckr [docker-options] [command] [args]
gdckr(){
  docker $@
}

# List docker images
# Usage: gdckri
gdckri(){
  gdckr images
}

# Run interactive docker container
# Usage: gdckrrit image_name [command]
gdckrrit(){
  gdckr run -it $@
}

# List running containers
# Usage: gdckrps [options]
gdckrps(){
  gdckr ps $@
}

# Stop running container(s)
# Usage: gdckrstp container_id [container_ids...]
gdckrstp(){
  gdckr stop $@
}

