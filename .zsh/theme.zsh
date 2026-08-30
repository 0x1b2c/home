autoload colors; colors

ZSH_THEME_GIT_PROMPT_PREFIX=" git:(%{$fg[blue]%}"
ZSH_THEME_GIT_PROMPT_SUFFIX="%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_DIRTY="%{$reset_color%}) %{$fg[yellow]%}✗%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_CLEAN="%{$reset_color%})"

source ~/.zsh/git.zsh

# Comment out the block below to disable the prompt.
function precmd {

    local TERMWIDTH
    (( TERMWIDTH = ${COLUMNS} - 1 ))

    ###
    # Truncate the path if it's too long.

    PR_FILLBAR=""
    PR_PWDLEN=""

    local promptsize=${#${(%):---(%n@%m:%l)---()--}}
    local pwdsize=${#${(%):-%~}}

    if [[ "$promptsize + $pwdsize" -gt $TERMWIDTH ]]; then
        ((PR_PWDLEN=$TERMWIDTH - $promptsize))
    else
        PR_FILLBAR="\${(l.(($TERMWIDTH - ($promptsize + $pwdsize)))..${PR_HBAR}.)}"
    fi

    ###
    # Get APM info.

    # if which ibam > /dev/null; then
    # PR_APM_RESULT=`ibam --percentbattery`
    # elif which apm > /dev/null; then
    # PR_APM_RESULT=`apm`
    # fi
}


setopt extended_glob

function preexec {
    if [[ "$TERM" == "screen" ]]; then
        local CMD=${1[(wr)^(*=*|sudo|-*)]}
        echo -n "\ek$CMD\e\\"
    fi

    print -rn -- $terminfo[el]
}

# ─── Command duration ───────────────────────────────────────────────
# EPOCHREALTIME rather than $SECONDS, which cannot tell 1.9s from 2.1s.
# Registered as hooks because rc.zsh already defines precmd and preexec
# for the terminal title.
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

setopt prompt_subst

function setprompt {
    ###
    # Need this so the prompt will work.

    setopt prompt_subst


    ###
    # See if we can use colors.

    autoload colors zsh/terminfo
    if [[ "$terminfo[colors]" -ge 8 ]]; then
        colors
    fi
    for color in RED GREEN YELLOW BLUE MAGENTA CYAN WHITE; do
        eval PR_$color='%{$terminfo[bold]$fg[${(L)color}]%}'
        eval PR_LIGHT_$color='%{$fg[${(L)color}]%}'
        (( count = $count + 1 ))
    done
    PR_NO_COLOUR="%{$terminfo[sgr0]%}"


    ###
    # See if we can use extended characters to look nicer.

    typeset -A altchar
    set -A altchar ${(s..)terminfo[acsc]}
    PR_SET_CHARSET="%{$terminfo[enacs]%}"
    PR_SHIFT_IN="%{$terminfo[smacs]%}"
    PR_SHIFT_OUT="%{$terminfo[rmacs]%}"
    PR_HBAR=${altchar[q]:--}
    # PR_HBAR=" "
    PR_ULCORNER=${altchar[l]:--}
    PR_LLCORNER=${altchar[m]:--}
    PR_LRCORNER=${altchar[j]:--}
    PR_URCORNER=${altchar[k]:--}


    ###
    # Decide if we need to set titlebar text.

    case $TERM in
        xterm*)
        PR_TITLEBAR=$'%{\e]0;%(!.-=*[ROOT]*=- | .)%n@%m:%~ | ${COLUMNS}x${LINES} | %y\a%}'
        ;;
        screen)
        PR_TITLEBAR=$'%{\e_screen \005 (\005t) | %(!.-=[ROOT]=- | .)%n@%m:%~ | ${COLUMNS}x${LINES} | %y\e\\%}'
        ;;
        *)
        PR_TITLEBAR=''
        ;;
    esac


    ###
    # Decide whether to set a screen title
    if [[ "$TERM" == "screen" ]]; then
        PR_STITLE=$'%{\ekzsh\e\\%}'
    else
        PR_STITLE=''
    fi


    ###
    # APM detection

    # if which ibam > /dev/null; then
        # PR_APM='$PR_RED${${PR_APM_RESULT[(f)1]}[(w)-2]}%%(${${PR_APM_RESULT[(f)3]}[(w)-1]})$PR_LIGHT_BLUE:'
    # elif which apm > /dev/null; then
        # PR_APM='$PR_RED${PR_APM_RESULT[(w)5,(w)6]/\% /%%}$PR_LIGHT_BLUE:'
    # else
        PR_APM=''
    # fi


    ###
    # Finally, the prompt.

    PROMPT_LINE1="$PR_SET_CHARSET$PR_STITLE${(e)PR_TITLEBAR}%{$fg[cyan]%}%n%{$fg[magenta]%}@%{$fg[blue]%}%M %{$fg[green]%}%~%{$reset_color%}\$(git_prompt_info)\${CMD_DURATION}"
    PROMPT_LINE2="%{$fg[red]%}%#%{$reset_color%} YUKI.N> "
    PROMPT="$PROMPT_LINE1
$PROMPT_LINE2"
}

setprompt

function zle-line-init zle-line-finish zle-keymap-select {
    terminfo_down_sc=$terminfo[cud1]$terminfo[cuu1]$terminfo[sc]$terminfo[cud1]
    MODE_INDICATOR="${${KEYMAP/vicmd/"%F{red}-- NORMAL --%f"}/(main|viins)/"%F{green}-- INSERT --%f"}"
    PROMPT="$PROMPT_LINE1
%{$terminfo_down_sc$MODE_INDICATOR$terminfo[rc]%}$PROMPT_LINE2"

    zle reset-prompt
    zle -R
}

zle -N zle-line-init
zle -N zle-line-finish
zle -N zle-keymap-select

# vim:set ft=zsh:
