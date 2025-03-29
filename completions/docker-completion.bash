# Docker command completions
_gdckr_completion() {
  local cur=${COMP_WORDS[COMP_CWORD]}
  local prev=${COMP_WORDS[COMP_CWORD-1]}
  
  case ${prev} in
    gdckrrit|gdckrstp)
      COMPREPLY=( $(docker ps --format '{{.Names}}' 2>/dev/null) )
      ;;
    *)
      COMPREPLY=( $(compgen -W "ps images run stop" -- "${cur}") )
      ;;
  esac
}

complete -F _gdckr_completion gdckr
complete -F _gdckr_completion gdckri
complete -F _gdckr_completion gdckrrit
complete -F _gdckr_completion gdckrps
complete -F _gdckr_completion gdckrstp