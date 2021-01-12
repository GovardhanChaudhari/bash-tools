#!/bin/bash

alias gs='git status'
alias gp='git push'
alias grm='git rm $*'

alias x='chmod +x $1'
alias c='touch $1'

# Slows down the interaction, so not preferred way
alias cl='cat $1 | less'

alias wrf='watch -n 0.4 "$*"'
alias t='tail -f "$@"'
alias rs=redshift
alias cpzshrc="cp ${HOME}/.zshrc ${GVC_BASH_TOOLS_HOME}/dotfiles/zsh/zshrc.symlink"
alias cpvimrc="cp ${HOME}/.vimrc ${GVC_BASH_TOOLS_HOME}/dotfiles/vim/vimrc.symlink"

alias cptmuxconf="cp ${HOME}/.tmux.conf ${GVC_BASH_TOOLS_HOME}/dotfiles/tmux/tmux.conf.symlink"
alias editvimrc="vim ${HOME}/.vimrc"
alias editzshrc="vim ${HOME}/.zshrc"
