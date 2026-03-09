
# Source: https://raw.githubusercontent.com/daniel7grant/dx

_dx()
{
    local cur prev opts
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    COMPREPLY=( $(compgen -W "$(docker ps --format '{{ .Names }}')" -- ${cur}) )
    return 0
}
complete -F _dx dx