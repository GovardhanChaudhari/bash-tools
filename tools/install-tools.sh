#! /bin/bash

gbt-install-tools(){
 sudo apt-get update 
 sudo apt-get install curl

 # Install lazydocker 
 curl https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash

 # Install laztgit
 install-lazygit

}

install-lazygit(){
 LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | \grep -Po '"tag_name": *"v\K[^"]*')
 curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
 tar xf lazygit.tar.gz lazygit
 rm lazygit.tar.gz
 sudo install lazygit -D -t /usr/local/bin/
 rm lazygit
}

