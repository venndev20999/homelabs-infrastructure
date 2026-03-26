[ -z "$PS1" ] && return

alias ls='ls --color=auto'
alias ll='ls --color=auto -lh'
alias la='ls --color=auto -A'
alias lla='ls --color=auto -lhA'
alias all='ls --color=auto -lhA'

alias ..="cd .."
alias ...="cd ../.."

alias diff='diff --color=auto'
alias grep='grep --color=auto'
alias ping='ping -c 5'
alias date='date +"%A, %B %d, %r"'

alias nano='nano -w'

alias rm='rm -Iv'
alias cp='cp -iv'
alias rsync='rsync -v'
alias chown='chown -c --preserve-root'
alias chmod='chmod -c --preserve-root'
alias chgrp='chgrp -c --preserve-root'

alias sudo='sudo '     # Allow the passing of aliases to sudo

# PS1
# - format:      0:normal 1:bold 4:under 0m:reset
# - text:       30:black 31:red 32:green 33:yellow 34:blue 35:purple 36:cyan 37:white
# - background: 40:black 41:red 42:green 43:yellow 44:blue 45:purple 46:cyan 47:white

# PS1
if [ $UID = 0 ]; 
  then
PS1='\[\e[0;32m\]Inspire> \[\e[0;31m\]root\
\[\e[0;37m\]@\[\e[0;31m\]\h\[\e[0;37m\]:\[\e[1;34m\]\w \
\[\e[1;32m\]{BE CAREFUL}\n\[\e[1;31m\]\$\[\e[0m\] '
  else
PS1='\[\e[0;32m\]Inspire> \[\e[0;31m\]\u\
\[\e[0;37m\]@\[\e[0;31m\]\h\[\e[0;37m\]:\[\e[1;34m\]\w\
\n\[\e[0;32m\]\$\[\e[0m\] '
fi    

export EDITOR="nano" 
export PYTHONSTARTUP="${HOME}/.pyrc"
export HISTCONTROL=ignoredups

complete -cf sudo
complete -cf man


cl() {
        local dir="$1"
        local dir="${dir:=$HOME}"
        if [[ -d "$dir" ]]; then
                cd "$dir" >/dev/null; ls
        else
                echo "bash: cl: $dir: Directory not found"
        fi
}