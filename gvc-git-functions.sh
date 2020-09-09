gc(){
  git commit -m "$1"
}

gcp(){
    gc $* && gp
}

gco(){
  git checkout "$1"
}

# Checkout master branch
gcom(){
  gco master
}

# Checkout dev branch
gcod(){
  gco dev
}

git_merge(){
  git merge "$1"
}

# merge given branch to master
gmm(){
  gcom
  git_merge "$1"
  gp
  gco "$1"
}

# Merge dev branch to master branch
gmdm(){
  gcom
  git_merge dev
  gp
  gcod
}