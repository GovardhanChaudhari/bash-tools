#!/bin/bash

# Commit changes
gc(){
  git commit -m "$1"
}

# Commit and push
gcp(){
    gc $* && gp
}

# Add current changes
git_add(){
   git add "$@"
}

# git_add function alias
gga(){
   git_add "$@"
}

# Git add and commit
gac(){
  git_add "$1"
  gc "$2"
}

# Git add, commit and push
gacp(){
  gac "$@"
  gp
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

# Alias for git_merge function
gm(){
  git_merge "$@"
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

# Set branch upstream
gbsu(){
  git push --set-upstream origin "$1"
}


# List git branches
gbl(){
  git branch "$@"
}

get_current_branch_name(){
  local branch_name=$(gbl | awk '{print $2}')
  echo $branch_name
}

# Restore file to its original state
grst(){
  git restore "$1"
}

# Delete remote branch
gdrb(){
  git push origin --delete "$1"
}

# Delete local branch
gdb(){
  git branch -d "$1"
}
# Clone
ggcl(){
  git clone $1
}