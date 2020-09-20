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

#Merge current brabch to master
gmtm(){
  local currentBranch=`get_current_branch_name`
  gcom
  git_merge "$currentBranch"
  gp
  gco "$currentBranch"
}

#Create git branch 
gb(){
  git branch "$1"
}

# List git branches
gbl(){
  git branch
}

get_current_branch_name(){
  local branch_name=$(gbl | awk '{print $2}')
  echo $branch_name
}

# Restore file to its original state
grst(){
  git restore "$1"
}