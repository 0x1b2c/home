# The fallback prompt, loaded by rc.zsh only when nothing else has claimed the
# prompt. Two lines:
#
#     user@host ~/src/foo git:(master ✗) 12.4s
#     % YUKI.N>                                          -- INSERT --
#
# Everything that used to draw a horizontal rule and rounded corners is gone;
# it was computed on every prompt and had not appeared on screen for years.

autoload -Uz colors && colors
setopt prompt_subst

# Git ------------------------------------------------------------------------------------------------------------- {{{1
#
# parse_git_dirty runs `git status` on every prompt, so this is the expensive
# part of the prompt in a large repository.
ZSH_THEME_GIT_PROMPT_PREFIX=" git:(%{$fg[blue]%}"
ZSH_THEME_GIT_PROMPT_SUFFIX="%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_DIRTY="%{$reset_color%}) %{$fg[yellow]%}✗%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_CLEAN="%{$reset_color%})"

parse_git_dirty() {
    if [[ -n $(git status -s --ignore-submodules 2> /dev/null) ]]; then
        echo "$ZSH_THEME_GIT_PROMPT_DIRTY"
    else
        echo "$ZSH_THEME_GIT_PROMPT_CLEAN"
    fi
}

git_prompt_info() {
    local ref
    ref=$(git symbolic-ref HEAD 2> /dev/null) || return
    echo "$ZSH_THEME_GIT_PROMPT_PREFIX${ref#refs/heads/}$(parse_git_dirty)$ZSH_THEME_GIT_PROMPT_SUFFIX"
}
# ----------------------------------------------------------------------------------------------------------------- }}}1

# Command duration ------------------------------------------------------------------------------------------------ {{{1
#
# EPOCHREALTIME rather than $SECONDS, which cannot tell 1.9s from 2.1s.
# Registered as hooks because rc.zsh already has precmd and preexec of its own.
zmodload zsh/datetime
autoload -Uz add-zsh-hook

# Below this the number is just noise. Same default as starship.
CMD_DURATION_MIN=2
CMD_DURATION=''

_cmd_duration_format() {
    local -F t=$1
    local -i s=$(( t ))
    if (( s < 60 )); then
        printf '%.1fs' $t
    elif (( s < 3600 )); then
        printf '%dm%02ds' $(( s / 60 )) $(( s % 60 ))
    else
        printf '%dh%02dm' $(( s / 3600 )) $(( s % 3600 / 60 ))
    fi
}

_cmd_duration_preexec() {
    _cmd_duration_start=$EPOCHREALTIME
}

_cmd_duration_precmd() {
    # No preexec means an empty line or the first prompt: nothing to report.
    if (( _cmd_duration_start )); then
        local -F elapsed=$(( EPOCHREALTIME - _cmd_duration_start ))
        unset _cmd_duration_start
        if (( elapsed >= CMD_DURATION_MIN )); then
            CMD_DURATION=" %{$fg[yellow]%}$(_cmd_duration_format $elapsed)%{$reset_color%}"
            return
        fi
    fi
    CMD_DURATION=''
}

add-zsh-hook preexec _cmd_duration_preexec
add-zsh-hook precmd  _cmd_duration_precmd
# ----------------------------------------------------------------------------------------------------------------- }}}1

# Prompt ---------------------------------------------------------------------------------------------------------- {{{1
#
# The two lines are kept in variables because the vi mode indicator below has to
# rebuild PROMPT from them on every keymap change.
#
# No title escape here: rc.zsh sets the terminal title from its own precmd hook,
# which works whichever prompt is in use.
# The leading blank line is what starship does by default: without it the output
# of the previous command runs straight into the prompt.
PROMPT_LINE1=$'\n'"%{$fg[cyan]%}%n%{$fg[magenta]%}@%{$fg[blue]%}%M %{$fg[green]%}%~%{$reset_color%}\$(git_prompt_info)\${CMD_DURATION}"
PROMPT_LINE2="%{$fg[red]%}%#%{$reset_color%} YUKI.N> "
PROMPT="$PROMPT_LINE1
$PROMPT_LINE2"
# ----------------------------------------------------------------------------------------------------------------- }}}1

# Vi mode indicator ----------------------------------------------------------------------------------------------- {{{1
#
# Printed one line below the cursor and restored, so it sits at the right of the
# second prompt line without being part of it.
function zle-line-init zle-line-finish zle-keymap-select {
    local down_sc=$terminfo[cud1]$terminfo[cuu1]$terminfo[sc]$terminfo[cud1]
    local indicator="${${KEYMAP/vicmd/"%F{red}-- NORMAL --%f"}/(main|viins)/"%F{green}-- INSERT --%f"}"
    PROMPT="$PROMPT_LINE1
%{$down_sc$indicator$terminfo[rc]%}$PROMPT_LINE2"

    zle reset-prompt
    zle -R
}

zmodload zsh/terminfo
zle -N zle-line-init
zle -N zle-line-finish
zle -N zle-keymap-select

# The indicator sits on the line below the prompt, which is where a command's
# output begins once you press return. Erase that line first, or the output
# overwrites only as much of the indicator as it is long and the tail of it
# stays on screen: ls printing "bin/  home/" over "-- INSERT --" leaves a "-".
#
# Autoloaded here rather than relied on from an earlier section, so this block
# does not depend on the order the file is read in.
autoload -Uz add-zsh-hook
_erase_indicator_line() { print -rn -- $terminfo[el] }
add-zsh-hook preexec _erase_indicator_line
# ----------------------------------------------------------------------------------------------------------------- }}}1

# vim: set fdm=marker fdl=0 tw=120:
