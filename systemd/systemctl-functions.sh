systemctl_command="systemctl"

# List
gsl(){
  $systemctl_command $@
}

# List services
gsls(){
  gsl -t service
}

# Status
gss(){
  gsl status $@
}
