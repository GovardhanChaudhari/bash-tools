systemctl_command="systemctl"

# Status
gss(){
  $systemctl_command status $1
}
