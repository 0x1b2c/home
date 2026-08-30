# What zsh itself does. Third-party tools live in external.zsh, the commands you
# define in shellrc.zsh, PATH in paths.zsh. Sections run in the order they must:
# history, keys, completion, directories, terminal, session, and last of all the
# hand-off to tmux.
#
# Loaded from ~/.zshrc, so interactive shells only, after ~/.zshenv and
# ~/.zprofile have set the environment and PATH. It is this file that pulls in
# shellrc.zsh, external.zsh and theme.zsh, each at the point it requires.

# History --------------------------------------------------------------------------------------------------------- {{{1
#
# 1. Basics
# Same path as /etc/zshrc uses. Anywhere else splits the history with shells that
# never reach this file.
HISTFILE="$HOME/.zsh_history"
HISTSIZE=10000000                # lines kept in memory
SAVEHIST=10000000                # lines saved to the file

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
setopt HIST_EXPIRE_DUPS_FIRST    # once the file is genuinely full, duplicates go first
setopt HIST_IGNORE_SPACE         # a leading space keeps a command out
setopt HIST_VERIFY               # expand a history reference without running it
setopt HIST_REDUCE_BLANKS        # strip redundant whitespace
# ----------------------------------------------------------------------------------------------------------------- }}}1

# Key bindings ---------------------------------------------------------------------------------------------------- {{{1
#
# Vi style key bindings
bindkey -v

# Up and Down walk only this shell's own commands; Ctrl-R still searches all of
# history. zsh has no option for this: set-local-history filters lines imported
# from other running shells, not the file read at startup, so the boundary has
# to be remembered by hand.
#
# The floor must be taken at the first prompt, not here: zsh reads the history
# file after the rc files, so $HISTCMD is still 1 at this point.
autoload -Uz add-zsh-hook
typeset -gi _hist_floor=0
_set_hist_floor() { (( _hist_floor )) || _hist_floor=$HISTCMD }
add-zsh-hook precmd _set_hist_floor

# The test has to come before the move: assigning HISTNO afterwards does not put
# BUFFER back, so clamping on the way out does not work.
up-session-history() { (( HISTNO > _hist_floor )) && zle up-line-or-history }
down-session-history() { zle down-line-or-history }
zle -N up-session-history
zle -N down-session-history

# Arrow keys send \e[A in normal cursor mode and \eOA in application mode, and
# which one arrives depends on the terminal, so bind both forms.
zmodload zsh/terminfo
bindkey -M viins "$terminfo[kcuu1]" up-session-history
bindkey -M viins "$terminfo[kcud1]" down-session-history
bindkey -M viins '^[[A'             up-session-history
bindkey -M viins '^[[B'             down-session-history
bindkey -M vicmd '^[[A'             up-session-history
bindkey -M vicmd '^[[B'             down-session-history
bindkey -M vicmd 'k'                up-session-history
bindkey -M vicmd 'j'                down-session-history

# Which characters Ctrl-W and friends treat as part of a word rather than a
# boundary. Shorter than the default, so paths and options break apart.
WORDCHARS='*?_-[]~=&;!#$%^(){}<>'
# ----------------------------------------------------------------------------------------------------------------- }}}1

# Completion ------------------------------------------------------------------------------------------------------ {{{1
#
setopt AUTO_LIST                 # list choices on an ambiguous completion
setopt AUTO_MENU                 # a second Tab starts cycling through them
setopt MENU_COMPLETE             # the first Tab already inserts the first match

# compinit has to run before anything calls compdef, which shellrc.zsh does.
# The dump is cache, not configuration, so it lives with the other cache; unlike
# _store_cache, compinit does not create the directory itself.
() {
    local d=${XDG_CACHE_HOME:-$HOME/.cache}/zsh
    [[ -d $d ]] || mkdir -p $d
    autoload -Uz compinit
    compinit -d $d/zcompdump
}

# Complete from words already in the history with M-/ and M-,
zstyle ':completion:history-words:*' list yes
zstyle ':completion:history-words:*' menu yes
zstyle ':completion:history-words:*' remove-all-dups yes
bindkey "\e/" _history-complete-older
bindkey "\e," _history-complete-newer

# Expensive completions (brew formulae, installed apps) keep a cache on disk.
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path ${XDG_CACHE_HOME:-$HOME/.cache}/zsh
# zstyle ':completion:*:cd:*' ignore-parents parent pwd

# Completion Options
# Try exact matches, then patterns, then approximate matches with at most one
# typo. Order matters: each is only tried when the previous one found nothing.
zstyle ':completion:*' completer _complete _match _approximate
zstyle ':completion:*:match:*' original only
zstyle ':completion:*:approximate:*' max-errors 1 numeric
zstyle ':completion::prefix-1:*' completer _complete
zstyle ':completion:predict:*' completer _complete
zstyle ':completion:incremental:*' completer _complete _correct

# Path Expansion
zstyle ':completion:*' expand 'yes'            # expand ~ and variables while completing
zstyle ':completion:*' squeeze-slashes 'yes'   # treat foo//bar as foo/bar

zstyle ':completion:*:*:*:default' menu no select
zstyle ':completion:*:*:default' force-list always

# Colour the menu the way ls colours a listing. -e defers the value until the
# style is looked up, so $LS_COLORS may be set anywhere, before or after this,
# and may change during the session. external.zsh is where it gets filled in.
zmodload zsh/complist
zstyle -e ':completion:*' list-colors 'reply=(${(s.:.)LS_COLORS})'
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#)*=0=01;31'

zstyle ':completion:*:*:kill:*' menu no select
zstyle ':completion:*:processes' command 'ps -au$USER'

# Group the matches by what they are and label each group
zstyle ':completion:*:matches' group 'yes'
zstyle ':completion:*:options' description 'yes'
zstyle ':completion:*:options' auto-description '%d'
zstyle ':completion:*:descriptions' format $'\e[01;33m -- %d --\e[0m'
zstyle ':completion:*:messages' format $'\e[01;35m -- %d --\e[0m'
zstyle ':completion:*:warnings' format $'\e[01;31m -- No Matches Found --\e[0m'

# Needs compinit above: shellrc.zsh registers completions with compdef.
[ -f ~/.zsh/shellrc.zsh ] && . ~/.zsh/shellrc.zsh
# ----------------------------------------------------------------------------------------------------------------- }}}1

# Directories ----------------------------------------------------------------------------------------------------- {{{1
#
setopt auto_pushd                # every cd pushes onto the stack, so `cd -<Tab>` works
# * matches dotfiles, which is why `ls *` and Tab show them without typing the
# leading dot. The same applies to `rm *`, which then takes .git with it.
setopt globdots

# Named directories, so that cd ~xxx works
hash -d VHOST="/var/www/vhosts"
hash -d AS="$HOME/Library/Application Support"
hash -d Preferences="$HOME/Library/Preferences"
hash -d Containers="$HOME/Library/Containers"
# ----------------------------------------------------------------------------------------------------------------- }}}1

# Terminal -------------------------------------------------------------------------------------------------------- {{{1
#
# Put the working directory in the tab title while idle and the running command
# while busy, via OSC 0. (V) renders control characters visible, so a hostile
# path or command cannot inject escape sequences into the title.
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
# ----------------------------------------------------------------------------------------------------------------- }}}1

# Session --------------------------------------------------------------------------------------------------------- {{{1
#
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
# ----------------------------------------------------------------------------------------------------------------- }}}1

# Hand-off -------------------------------------------------------------------------------------------------------- {{{1
#
# NOTE: this is the last thing the file does and has to stay that way. The
# command blocks until tmux exits, so anything placed below it would only run
# after a detach, and a new tmux server would inherit an environment that was
# still half configured. Add new things above this line.
#
# No general way to tell whether a multiplexer is already running, so the rule
# is just: not in tmux, plus a whitelist of SSH, WSL and the Linux console.
# Local WezTerm and Ghostty stay out; a tmux per tab is absurd.
if [[ -z $TMUX && ( -n $SSH_TTY || -n $WSL_DISTRO_NAME || $TERM == linux ) ]]; then
    tmux new -As main
fi
# ----------------------------------------------------------------------------------------------------------------- }}}1

# vim: set fdm=marker fdl=0 tw=120:
