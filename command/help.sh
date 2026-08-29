# show help of command 
gh(){ $1 --help }

# show hwlp of command in less
ghl(){ gh $@ | less }
