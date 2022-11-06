gsctl(){
 systemctl $@
}

# List
gsl(){
  gsctl $@
}

# List services
gsls(){
  gsl -t service $@
}

# List running services
gslrs(){
  gsls --state=running $@
}

# Status
gss(){
  gsctl status $@
}

# stop
gsstps(){
	gsctl stop $@
}

# start service
gssrts(){
	gsctl start $@
}

# disable service
gsds(){
	gsctl disable $@
}

# enable service
gses(){
	gsctl enable $@
}
