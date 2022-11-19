#!/bin/bash
parent_dir="$GVC_BASH_TOOLS_HOME"
source $parent_dir/utils/utils.sh
source $parent_dir/utils/download.sh
source $parent_dir/bash/bash_aliases.sh
source $parent_dir/bash/bash-functions.sh
source $parent_dir/file/gvc-file-utils.sh
source $parent_dir/command/gvc-command-utils.sh
source $parent_dir/command/help.sh
source $parent_dir/command/find.sh
source $parent_dir/git/gvc-git-functions.sh

source $parent_dir/dev/bash-tools-utils.sh

source $parent_dir/zsh/zsh-functions.sh
#Kubernetes Functions
source $parent_dir/kubernetes/kubectl-functions.sh

source $parent_dir/systemd/systemctl-functions.sh
source $parent_dir/sys-utils/sys.sh

source $parent_dir/docker/docker.sh

source $parent_dir/docker/docker-compose.sh

source $parent_dir/apt/apt.sh

source $parent_dir/vim/vim-functions.sh

source $parent_dir/nmap/nmap.sh


source $parent_dir/tmux/tmux.sh
