# Base apt command with sudo
# Usage: aptcmd [apt-options] [command] [package-names]
aptcmd(){ sudo apt $@ }

# Install package(s)
# Usage: gi package1 [package2...]
gi(){ aptcmd install $@ }

# Update package list
# Usage: gu
gu(){ aptcmd update $@ }

# Upgrade all upgradable packages
# Usage: ggup
ggup(){ aptcmd upgrade $@ }

# Full upgrade (dist-upgrade)
# Usage: gfup
gfup(){ aptcmd fullupgrade $@ }

# List upgradable packages
# Usage: glu
glu(){ aptcmd list --upgradable }

# List installed packages
# Usage: gli [pattern]
gli(){ aptcmd list --installed }

# Remove unnecessary packages
# Usage: gatr
gatr(){ aptcmd autoremove $@ }

# Remove package(s)
# Usage: gar package1 [package2...]
gar(){ aptcmd remove $@ }

# Show package information
# Usage: gas package-name
gas(){ aptcmd show $@ }
