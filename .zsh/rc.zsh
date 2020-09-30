# location of history
export HISTFILE=~/.zsh/history
# number of lines kept in history
HISTSIZE=100000
# number of lines saved in the history after logout
SAVEHIST=100000

setopt append_history
setopt extended_history
setopt hist_expire_dups_first
setopt hist_ignore_dups # ignore duplication command history list
setopt hist_ignore_space
setopt hist_verify
setopt inc_append_history
setopt share_history # share command history data

# TODO bindkeys for them in vi mode
# bindkey "${key[Up]}" up-line-or-local-history
# bindkey "${key[Down]}" down-line-or-local-history

up-line-or-local-history() {
    zle set-local-history 1
    zle up-line-or-history
    zle set-local-history 0
}
zle -N up-line-or-local-history
down-line-or-local-history() {
    zle set-local-history 1
    zle down-line-or-history
    zle set-local-history 0
}
zle -N down-line-or-local-history

setopt auto_pushd

# Vi 风格键绑定
bindkey -v
bindkey '^R' history-incremental-search-backward

# 以下字符视为单词的一部分
WORDCHARS='*?_-[]~=&;!#$%^(){}<>'

# 自动补全功能
setopt AUTO_LIST
setopt AUTO_MENU
setopt MENU_COMPLETE

autoload -U compinit
compinit

# Complete in history with M-/, M-,
zstyle ':completion:history-words:*' list yes
zstyle ':completion:history-words:*' menu yes
zstyle ':completion:history-words:*' remove-all-dups yes
bindkey "\e/" _history-complete-older
bindkey "\e," _history-complete-newer

# Completion caching
zstyle ':completion::complete:*' use-cache on
zstyle ':completion::complete:*' cache-path ~/.zsh/cache
# zstyle ':completion:*:cd:*' ignore-parents parent pwd

# Completion Options
zstyle ':completion:*:match:*' original only
zstyle ':completion::prefix-1:*' completer _complete
zstyle ':completion:predict:*' completer _complete
zstyle ':completion:incremental:*' completer _complete _correct
zstyle ':completion:*' completer _complete _prefix _correct _prefix _match _approximate

# Path Expansion
zstyle ':completion:*' expand 'yes'
zstyle ':completion:*' squeeze-shlashes 'yes'
zstyle ':completion::complete:*' '\\'

zstyle ':completion:*:*:*:default' menu no select
zstyle ':completion:*:*:default' force-list always

# 自动补全时候选菜单中的选项使用 dircolors 设定的彩色显示
if [[ ! ($OSTYPE == darwin*) ]]; then
    eval $(dircolors -b)
    export ZLSCOLORS="${LS_COLORS}"
fi
zmodload zsh/complist
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#)*=0=01;31'

zstyle ':completion:*' completer _complete _match _approximate
zstyle ':completion:*:match:*' original only
zstyle ':completion:*:approximate:*' max-errors 1 numeric

compdef pkill=kill
compdef pkill=killall
zstyle ':completion:*:*:kill:*' menu no select
zstyle ':completion:*:processes' command 'ps -au$USER'

# Group matches and Describe
zstyle ':completion:*:matches' group 'yes'
zstyle ':completion:*:options' description 'yes'
zstyle ':completion:*:options' auto-description '%d'
zstyle ':completion:*:descriptions' format $'\e[01;33m -- %d --\e[0m'
zstyle ':completion:*:messages' format $'\e[01;35m -- %d --\e[0m'
zstyle ':completion:*:warnings' format $'\e[01;31m -- No Matches Found --\e[0m'

# Import .shellrc
[ -f ~/.shellrc ] && . ~/.shellrc

# 路径别名 进入相应的路径时只要 cd ~xxx
hash -d VHOST="/var/www/vhosts"
hash -d AS="$HOME/Library/Application Support"
hash -d Preferences="$HOME/Library/Preferences"
hash -d Containers="$HOME/Library/Containers"

# For Emacs在Emacs终端中使用Zsh的一些设置 不推荐在Emacs中使用它
if [[ "$TERM" == "dumb" ]]; then
    setopt No_zle
    PROMPT='%n@%M %/
    >>'
    alias ls='ls -F'
fi

if [[ -x `which starship` ]]; then
    eval "$(starship init zsh)"
else
    source ~/.zsh/theme.zsh
fi

source ~/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

source ~/.zsh/z/z.sh
export _Z_DATA=~/.zsh/cache/z

export PATH="$HOME/.rbenv/bin:$PATH"
if which rbenv > /dev/null; then eval "$(rbenv init -)"; fi

if [[ $TERM == linux ]]; then
    fbterm -- tmux new -As rainux
fi

if [[ -z $TMUX ]]; then
    tmux new -As rainux
fi
