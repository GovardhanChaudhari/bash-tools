#!/bin/bash

# Commit changes
ggc() {
  git commit -m "$@"
}

# Commit and push
ggcp(){
    ggc $* && gp
}

# Add current changes
git_add(){
   git add "$@"
}

# git_add function alias
gad(){
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

ggco(){
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
ggm(){
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
ggb(){
  git branch "$1"
}

# Set branch upstream
gbsu(){
  git push --set-upstream origin "$1"
}


# List git branches
ggbl(){
  git branch "$@"
}

get_current_branch_name(){
  local branch_name=$(gbl | awk '{print $2}')
  echo $branch_name
}

# Restore file to its original state
ggrst(){
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

# Avoid asking for passphrase every time during git operations
gsshadd(){
  eval "$(ssh-agent -s)"
  ssh-add ~/.ssh/id_ed25519 2>/dev/null
}