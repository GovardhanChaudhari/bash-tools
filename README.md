# Bash-tools
Note:
While checking out dev branch, use -- at the end of git command to differentiate between path and string as project directory contains dev directory.

Note:
While checking out dev branch, use -- at the end of git command to differentiate between path and string as project directory contains dev directory.

## Help
**gh** show help of given command | **ghl** show help in less

## Git
**gs** status | **gad** add | **gp** push | **grm** remove | **ggc** commit with message | **ggcp** commit and push | **ggco** checkout | **gcom** checkout master | **gcod** checkout dev | **gac** add and commit | **gacp** add, commit and push | **ggm** merge | **gmm** merge branch to master | **gmdm** merge dev to master | **gmtm** merge current branch to master | **ggb** create branch | **ggbl** list branches | **gdrb** delete remote branch | **gdb** delete local branch | **gbsu** set branch upstream | **ggrst** restore file | **ggcl** clone | **gsshadd** Avoid asking for passphrase every time during git operation

## Gvc bash tools
**gbtr** reload tools | **gbter** edit README | **gbth** show README | **gbtd** go to bash tools dir | **gbtei** edit index.sh 

## Bash commands
**c** create file | **glf** less file | **glc** less command | **x** make executable | **wf** watch file | **gfndc** find content in files | **gcls** clear screen | **gcdp** change to parent dir | **gmd** make directory | **grd** remove directory | **gcbf** create bash file | **cx** create executable bash file | **e** edit with vim | **gebrc** edit bashrc

## File utilities
**getCurrentFileName** get current file name | **getCurrentDir** get current directory | **getCurrentFullFilePath** get full file path | **get_relative_path** get relative path (WIP)

## apt
**gi** install | **gu** update | **ggup** upgrade | **gfup** full upgrade | **gli** list installed | **glu** list upgradable | **gar** remove | **gatr** auto remove | **gas** show package info

## Systemctl
**gsctl** base command | **ggss** status | **gsl** list | **gsls** list services | **gslrs** list running services | **gsstps** stop service | **gssrts** start service | **gsds** disable service | **gses** enable service

## system
**gpoff** power off | **grbt** reboot | **ghib** hibernate

## docker
**gdckr** base command | **gdckri** list images | **gdckrrit** run interactive | **gdckrps** ps | **gdckrstp** stop 

## docker compose
**gdckrc** base command | **gdckrcb** build | **gdckrcup** up | **gdckrcdwn** down

## rc files
**gezrc** edit zshrc | **gebrc** edit bashrc | **gevrc** edit vimrc

## Kubernetes
**gkga** Get all | **gkln** List namespaces | **gklp** List pods | **gkdb** Launch dashboard | **gkodb** Open dashboard | **gkdbt** Copy dashboard token to clipboard | **gkwd** Launch weave dashboard | **gkscn** Set current namespace | **gka** apply | **gkd** delete

## nmap
**gnmp** nmap base cmd | **gnmpos** scan for OS

## tmux
**gtmx** tmux base command | **gtma** attach to session | **Prefix + r** reload tmux config

## rpi4
**rpimt** show rpi temperature | **wrpimt** watch rpi temperature

## Command utilities
**isCommandExist** check if command exists | **getLastArgument** get last argument | **firstN** get first N arguments | **getArgsExceptLast** get all arguments except last

## Aliases
**wrf** watch with refresh | **t** tail follow | **rs** redshift | **cpzshrc** copy zshrc to dotfiles | **cpvimrc** copy vimrc to dotfiles | **cptmuxconf** copy tmux config to dotfiles | **editvimrc** edit vimrc | **editzshrc** edit zshrc | **edittmuxconf** edit tmux config | **gcsr** clear screen