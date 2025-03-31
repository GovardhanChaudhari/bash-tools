#!/bin/bash

# Commit changes with message
# Usage: ggc "commit message"
ggc() {
  git commit -m "$@"
}

# Commit changes and push to remote
# Usage: ggcp "commit message"
ggcp(){
    ggc $* && gp
}

# Stage files for commit
# Usage: git_add file1 [file2...]
git_add(){
   git add "$@"
}

# Alias for git_add
# Usage: gad file1 [file2...]
gad(){
   git_add "$@"
}

# Add changes and commit with message
# Usage: gac file "commit message"
gac(){
  git_add "$1"
  gc "$2"
}

# Add changes, commit and push
# Usage: gacp file "commit message"
gacp(){
  gac "$@"
  gp
}

# Checkout branch or commit
# Usage: ggco branch_name
ggco(){
  git checkout "$1"
}

# Checkout master branch
# Usage: gcom
gcom(){
  gco master
}

# Checkout dev branch
# Usage: gcod
gcod(){
  gco dev
}

# Merge branch into current branch
# Usage: git_merge branch_name
git_merge(){
  git merge "$1"
}

# Alias for git_merge
# Usage: ggm branch_name
ggm(){
  git_merge "$@"
}

# Merge branch to master and push
# Usage: gmm branch_name
gmm(){
  gcom
  git_merge "$1"
  gp
  gco "$1"
}

# Merge dev branch to master and push
# Usage: gmdm
gmdm(){
  gcom
  git_merge dev
  gp
  gcod
}

# Merge current branch to master and push
# Usage: gmtm
gmtm(){
  local currentBranch=`get_current_branch_name`
  gcom
  git_merge "$currentBranch"
  gp
  gco "$currentBranch"
}

# Create new git branch
# Usage: ggb branch_name
ggb(){
  git branch "$1"
}

# Set upstream for branch
# Usage: gbsu branch_name
gbsu(){
  git push --set-upstream origin "$1"
}

# List branches
# Usage: ggbl [options]
ggbl(){
  git branch "$@"
}

# Get current branch name
# Usage: get_current_branch_name
get_current_branch_name(){
  local branch_name=$(gbl | awk '{print $2}')
  echo $branch_name
}

# Restore file to last committed state
# Usage: ggrst filename
ggrst(){
  git restore "$1"
}

# Delete remote branch
# Usage: gdrb branch_name
gdrb(){
  git push origin --delete "$1"
}

# Delete local branch
# Usage: gdb branch_name
gdb(){
  git branch -d "$1"
}

# Clone repository
# Usage: ggcl repository_url
ggcl(){
  git clone $1
}

# Add SSH key to agent
# Usage: gsshadd
gsshadd(){
  eval "$(ssh-agent -s)"
  ssh-add ~/.ssh/id_ed25519 2>/dev/null
}