gc(){
  git commit -m "$1"
}

cx(){
  c "$1" && x "$1"
}

gcp(){
    gc $* && gp
}

gco(){
  git checkout "$1"
}

# merge given branch to master
gmm(){
  gco "master"
  git merge "$1"
  gp
  gco "$1"
}