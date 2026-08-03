# .bashrc

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto --hyperlink=auto'
alias tree='tree -C --hyperlink'
alias vim='nvim'
alias diff='riff'
alias less='moor'


source /usr/share/git/git-prompt.sh
PROMPT_COMMAND='PS1_CMD1=$(__git_ps1 "(%s)")'
PS1='\[\e[92m\]\u\[\e[0;2m\]@\[\e[0;96m\]\H\[\e[0m\] \[\e[93m\]\W\[\e[0m\]${PS1_CMD1}\n\[\e[92m\]\$\[\e[0m\] '

if [[ -n "$TTY" ]]; then
  export GPG_TTY=$(tty)
fi

export LANG=en_US.UTF-8 \
       PATH="$PATH:$HOME/.local/bin/"
