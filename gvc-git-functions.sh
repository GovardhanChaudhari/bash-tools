
gc(){
  git commit -m $1
}

cx(){
  c "$1" && x "$1"
}
