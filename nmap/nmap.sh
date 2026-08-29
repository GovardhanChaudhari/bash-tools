# nmap base command
gnmp(){ sudo nmap $@ }

# scan for os
gnmpos(){ gnmp -O $@ }


