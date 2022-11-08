# base command
aptcmd(){ sudo apt $@ }

# install
gi(){ aptcmd install $@ }

# update
gu(){ aptcmd update $@ }

# upgrade 
gup(){ aptcmd upgrade $@ }

# full upgrade
gfup(){ aptcmd fullupgrade $@}

# list upgradable
glu(){ aptcmd list --upgradable }

# autoremove
gatr(){ aptcmd autoremove $@ }

# remove
gar(){ aptcmd remove }
