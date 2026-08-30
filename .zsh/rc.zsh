# 1. Basics
# Same path as /etc/zshrc uses. Anywhere else splits the history with
# shells that never reach this file.
HISTFILE="$HOME/.zsh_history"
HISTSIZE=10000000        # lines kept in memory
SAVEHIST=10000000        # lines saved to the file

# 2. One file to write to, but tabs stay out of each other's way
setopt INC_APPEND_HISTORY        # append at once, so nothing is lost on a crash
unsetopt SHARE_HISTORY           # no live sharing; a tab reads history at startup only

# 3. What gets recorded
setopt EXTENDED_HISTORY          # timestamp and duration
setopt APPEND_HISTORY            # never truncate

# 4. Duplicates
setopt HIST_IGNORE_DUPS          # drop consecutive repeats only
unsetopt HIST_IGNORE_ALL_DUPS    # keep the rest: the order things were run in matters

# 5. Recall
# The file keeps duplicates; Up and Ctrl+R should not show them.
setopt HIST_FIND_NO_DUPS

# 6. Misc
setopt HIST_IGNORE_SPACE         # a leading space keeps a command out
setopt HIST_VERIFY               # expand a history reference without running it
setopt HIST_REDUCE_BLANKS        # strip redundant whitespace
setopt HIST_EXPIRE_DUPS_FIRST    # once the file is genuinely full, duplicates go first

setopt globdots

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

# Vi style key bindings
bindkey -v

# Characters treated as part of a word
WORDCHARS='*?_-[]~=&;!#$%^(){}<>'

# Completion
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

# Color the completion menu with dircolors
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

# Import shellrc
[ -f ~/.zsh/shellrc.zsh ] && . ~/.zsh/shellrc.zsh

# Named directories, so that cd ~xxx works
hash -d VHOST="/var/www/vhosts"
hash -d AS="$HOME/Library/Application Support"
hash -d Preferences="$HOME/Library/Preferences"
hash -d Containers="$HOME/Library/Containers"

function set-term-title-precmd() {
  emulate -L zsh
  print -rn -- $'\e]0;'${(V%):-'%~'}$'\a' >$TTY
}
function set-term-title-preexec() {
  emulate -L zsh
  print -rn -- $'\e]0;'${(V)1}$'\a' >$TTY
}
autoload -Uz add-zsh-hook
add-zsh-hook preexec set-term-title-preexec
add-zsh-hook precmd set-term-title-precmd
set-term-title-precmd

# An agent first, then the keys. On macOS the Keychain holds the passphrases,
# but only load them when the agent is empty: a locked Keychain otherwise turns
# every new shell into an interactive passphrase prompt.
if [[ -z $SSH_AUTH_SOCK ]]; then
    eval `ssh-agent`
fi
if [[ $OSTYPE == darwin* ]]; then
    ssh-add -l &> /dev/null || ssh-add --apple-use-keychain 2> /dev/null
fi

# Shell snippets shipped by other programs.
[ -f ~/.zsh/external.zsh ] && . ~/.zsh/external.zsh

# Fall back to the hand-written prompt when nothing out there claimed it.
# The test is on this shell's own state, not on $STARSHIP_SHELL, which is
# exported and would be inherited by shells that never ran starship at all.
(( $+functions[prompt_starship_precmd] )) || source ~/.zsh/theme.zsh

# NOTE: this hand-off is the last thing the file does and has to stay that way.
# The command blocks until tmux exits, so anything placed below it would only
# run after a detach, and a new tmux server would inherit an environment that
# was still half configured. Add new things above this line.
#
# No general way to tell whether a multiplexer is already running, so the rule
# is just: not in tmux, plus a whitelist of SSH, WSL and the Linux console.
# Local WezTerm and Ghostty stay out; a tmux per tab is absurd.
if [[ -z $TMUX && ( -n $SSH_TTY || -n $WSL_DISTRO_NAME || $TERM == linux ) ]]; then
    tmux new -As main
fi
