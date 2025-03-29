# Git command completions
_ggco_completion() {
  local cur=${COMP_WORDS[COMP_CWORD]}
  COMPREPLY=( $(compgen -W "$(git branch --list | sed 's/^\*\? *//')" -- "$cur") )
}

complete -F _ggco_completion ggco
complete -F _ggco_completion gcom
complete -F _ggco_completion gcod

_gac_completion() {
  local cur=${COMP_WORDS[COMP_CWORD]}
  case $COMP_CWORD in
    1) COMPREPLY=( $(compgen -f -- "$cur") ) ;;
    *) COMPREPLY=() ;;
  esac
}

complete -F _gac_completion gac
complete -F _gac_completion gacp