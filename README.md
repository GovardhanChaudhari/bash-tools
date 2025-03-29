# Bash-tools

## Installation
```bash
# Clone the repository
git clone https://github.com/govardhan-chaudhari/bash-tools.git
cd bash-tools

# Run the installer
./install.sh
```

## Testing
Tests require [bats-core](https://github.com/bats-core/bats-core):
```bash
cd tests
bats apt_tests.bats
```

## Contributing
1. Add documentation comments to new functions
2. Include corresponding test cases
3. Keep the modular structure
4. Follow existing naming conventions

Note:
While checking out dev branch, use -- at the end of git command to differentiate between path and string as project directory contains dev directory.

## Help
**gh** show help of given command | **ghl** show help in less

## Git
**gs** status | **gad** add | **gp** push | **grm** remove | **gc** commit | **gm** merge | **gcp** commit and push | **gco** checkout | **gcom** checkout master | **gcod** checkout dev | **gac** add and commit | **gacp** add, commit and push | **ggb** create branch | **ggbl** list branches | **gdrb** delete remote branch | **gdb** delete local branch | **gbsu** set branch upstream | **ggrst** restore file | **ggcl** clone | **gsshadd** Avoid asking for passphrase every time during git operations 

## Gvc bash tools
**gbtr** reload tools | **gbter** edit README | **gbth** show README |
**gbtd** go to bash tools dir | **gbtei** edit index.sh 

## Bash commands
**c** create file | **glf** less file | **glc** less command | **x** make executable | **wf** watch file | **gfndc** find content in files | **gcls** clear screen | **gcdp** change to parent dir | **gmd** make directory | **grd** remove directory | **gcbf** create bash file | **cx** create executable bash file | **e** edit with vim

## apt
**gi** install | **gu** update | **gup** upgrade | **gfup** full upgrade | **gli** list installed | **glu** list upgradable | **gar** remove | **gatr** auto remove | **gas** show package info

## Systemctl
**gsctl** base command | **gss** status | **gsls** list services | **gslrs** list running services | **gsstps** stop service | **gssrts** start service | **gsds** disable service | **gses** enable service

## system
**gpoff** power off | **grbt** reboot

## docker
**gdckr** base command | **gdckri** list images | **gdckrrit** run interactive | **gdckrps** ps | **gdckrstp** stop 

## docker compose
**gdckrc** base command | **gdckrcb** build | **gdckrcup** up | **gdckrcdwn** down

## rc files
**gezrc** edit zshrc | **gebrc** edit bashrc | **gevrc** edit vimrc

## Kubernetes
**gkga** Get all | **gkln** List namespaces | **gklp** List pods | **gkdb** Launch dashboard | **gkdbt** Copy dashboard token to clipboard | **gkwd** Launch weave dashboard | **gkscn** Set current namespace | **gka** apply | **gkd** delete

## nmap
**gnmp** nmap base cmd

## tmux
**gtma** attach | **ta** attach | **tls** list sessions | **tat** attach to session | **tns** new session

Note: Tmux resurrect plugin's imp env file is backedup in ./tmux/plugins/resurrect dir. Copy this file to ~/.tmux/resurrect dir create a symlink called 'last' to the same dir.

## rpi4
**rpimt** show rpi temperature
