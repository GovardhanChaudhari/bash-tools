# tmux base func
gtmx(){ tmux $@ }

# attach to session
gtma(){ gtmx a -t $@ }
