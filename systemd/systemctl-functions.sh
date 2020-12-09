systemctl_command="systemctl"

# List
gsl(){
  $systemctl_command $@
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
  gsl status $@
}
