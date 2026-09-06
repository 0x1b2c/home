# The reloadable half of the shell config. Everything here must be safe to
# run again at any moment: aliases, functions, and absolute assignments
# only. Nothing that accumulates, no setopt, no bindkey, no compinit.
# That invariant is what makes reload_shellrc work.
#
# Loaded from rc.zsh, and it has to stay after the compinit there: the compdef
# calls below fail without it.
alias reload_shellrc='source ~/.zsh/shellrc.zsh'
alias reload_paths='source ~/.zsh/paths.zsh'

# Aliases --------------------------------------------------------------------------------------------------------- {{{1
#
# General --------------------------------------------------------------------------------------------------------- {{{2
alias be='bundle exec'
alias c='claude'
alias cjob='new-claude-job'
alias cr='claude -r'
alias cs='FORCE_PROMPT_CACHING_5M=1 claude'
alias csr='FORCE_PROMPT_CACHING_5M=1 claude -r'
alias cxr='codex resume'
alias cz='chezmoi'
alias d='deploy'
alias dc='docker-compose'
alias dcl='docker context list'
alias dcu='docker context use'
alias f='fd -u -u'
alias fda='fd -I'
alias fdu='fd -u'
alias g='git'
alias gf='git-flow'
alias gldl='gallery-dl'
alias gr='gemini -r'
alias grep='grep --color'
alias gvi='NVIM_APPNAME=nvchad gvim'
alias ka='killall'
alias mpvq='mpv >/dev/null 2&>1'
alias psg='ps aux | grep'
alias pwgen='pwgen -s'
alias py='python'
alias r='rails'
alias rsync='rsync -PchavzX --stats'
alias sudo='sudo -E'
alias upgrade_gemini='bun add -g @google/gemini-cli@latest'
alias vi='NVIM_APPNAME=nvchad nvim'
alias vim='nvim'
alias vimdiff='nvim -d'
alias ytdl='yt-dlp --force-overwrites --cookies-from-browser brave'
alias ytdlmp4='yt-dlp --force-overwrites -f "bestvideo[ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best"'
alias ytdlsub='yt-dlp --write-sub --embed-subs --convert-subs srt --sub-lang'
# ----------------------------------------------------------------------------------------------------------------- }}}2

# OS specific ----------------------------------------------------------------------------------------------------- {{{2
if [[ $OSTYPE == darwin* ]]; then
    alias o='open'

    alias tmr='tmutil restore ~/TM'
else
    alias o='gnome-open'
    alias open='gnome-open'

    alias dstart='sudo systemctl start'
    alias drestart='sudo systemctl restart'
    alias dstop='sudo systemctl stop'
    alias dreload='sudo systemctl daemon-reload'
    alias jctl='journalctl -u'
    alias wicd='wicd-curses'
fi
# ----------------------------------------------------------------------------------------------------------------- }}}2

# Extra ----------------------------------------------------------------------------------------------------------- {{{2
if (( $+commands[eza] )); then
    alias ls='eza --binary --color-scale=all --hyperlink --icons=auto'
    alias lsa='ls --absolute=on --hyperlink'
elif [[ $OSTYPE == darwin* ]]; then
    alias ls='ls -GFh'
else
    alias ls='ls --color -hF --show-control-chars'
fi

if (( $+commands[bat] )); then
    alias cat='bat'
    alias less='bat'
else
    alias less='less -r'
fi

(( $+commands[curlie] )) && alias curl='curlie'
(( $+commands[dog] )) && alias dig='dog'
(( $+commands[mongosh] )) && alias mongo='mongosh'
(( $+commands[wget2] )) && alias wget='wget2'
# ----------------------------------------------------------------------------------------------------------------- }}}2

# Arch Linux ------------------------------------------------------------------------------------------------------ {{{2
alias pacman='pacman --color=auto'
alias pacupg='sudo pacman --color=auto -Syu'
alias pacupgd='sudo pacman --color=auto -Syud'
alias pacin='sudo pacman --color=auto -S'
alias pacins='sudo pacman --color=auto -Up'
alias pacre='sudo pacman --color=auto -R'
alias pacrem='sudo pacman --color=auto -Rns'
alias pacrep='pacman --color=auto -Si'
alias pacreps='pacman --color=auto -Ss'
alias pacloc='pacman --color=auto -Qi'
alias paclocs='pacman --color=auto -Qs'
alias pacupd='sudo pacman --color=auto -Sy && sudo abs'
alias pacinsd='sudo pacman --color=auto -S --nodeps'
alias pacmir='sudo pacman --color=auto -Syy'
alias pacfile='pacman --color=auto -Qo'
alias pacfiles='pacman --color=auto -Qlq'

alias yaoupg='yay -Syu --aur --devel'
alias yaoin='yay -S'
alias yaoins='yay -Up'
alias yaore='yay -R'
alias yaorem='yay -Rns'
alias yaorep='yay -Si'
alias yaoreps='yay -Ss'
alias yaoloc='yay -Qi'
alias yaolocs='yay -Qs'
alias yaoupd='yay -Sy && sudo abs'
alias yaoinsd='yay -S --nodeps'
alias yaomir='yay -Syy'
alias yaoget='yay -G'
# ----------------------------------------------------------------------------------------------------------------- }}}2
# ----------------------------------------------------------------------------------------------------------------- }}}1

# Environment ----------------------------------------------------------------------------------------------------- {{{1
#
# ANDROID_HOME, BUN_INSTALL, GOPATH are now in ~/.zsh/paths.zsh
export EZA_CONFIG_DIR="$HOME/.config/eza"
export FZF_DEFAULT_COMMAND='rg --hidden --no-ignore -l ""'
export FZF_DEFAULT_OPTS='--bind=ctrl-n:page-down,ctrl-p:page-up,ctrl-alt-f:forward-word,ctrl-alt-b:backward-word'
export GPG_TTY=$(tty)
export HOMEBREW_AUTO_UPDATE_SECS=86400
export MAA_CONFIG_DIR="$HOME/.maa/config"
export MAA_DATA_DIR="$HOME/.maa"
export MAA_STATE_DIR="$HOME/.maa"
export UV_NO_MANAGED_PYTHON=1

if [[ $OSTYPE == darwin* ]]; then
    export LANG='en_US.UTF-8'
else
    export LC_CTYPE='zh_CN.UTF-8'
fi
export EDITOR='nvim'

if [[ $TERM == xterm ]]; then
    export TERM='xterm-256color'
fi

if [[ $TERM == linux ]]; then
    export LANG='C'
fi
# ----------------------------------------------------------------------------------------------------------------- }}}1

# Functions ------------------------------------------------------------------------------------------------------- {{{1
#
# dash: pick a project from ~/.projects with fzf, cd into it, show git status if it is a repo. -------------------- {{{2
function dash() {
    local target
    # Strip comments and blank lines before fzf ever sees them.
    target=$(grep -vE '^\s*(#|$)' ~/.projects | fzf --prompt="⚡️ project > " --delimiter="|" --with-nth=1,2)

    if [[ -n "$target" ]]; then
        # cd rather than z, so that zoxide still scores the jump.
        local dir=$(echo "$target" | awk -F '|' '{print $1}' | tr -d ' ')
        cd "$dir" || return

        clear

        if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
            echo -e "\033[1;32m[🎯 project: $(basename "$PWD")]\033[0m"
            git status -sb
            echo ""
        else
            echo -e "\033[1;34m[📁 directory: $(basename "$PWD")]\033[0m\n"
        fi
    fi
}
# ----------------------------------------------------------------------------------------------------------------- }}}2

# diff: colourised diff through delta, keeping diff's own exit status rather than delta's. ------------------------ {{{2
if (( $+commands[delta] )); then
    diff() {
        command diff -ur "$@" | delta
        return $pipestatus[1]
    }
    compdef _diff diff
fi
# ----------------------------------------------------------------------------------------------------------------- }}}2

# dirdiffs: compare two trees by the sha256 of every file. Read-only, writes and deletes nothing. ----------------- {{{2
#   dirdiffs <a> <b>
# No output means identical; < and > lines are files that differ or exist on one side only.
dirdiffs() {
    [ $# -eq 2 ] || {
        echo "Usage: dirdiffs <a> <b>" >&2
        return 2
    }
    local hash
    if command -v sha256sum >/dev/null; then
        hash=sha256sum
    else
        hash="shasum -a 256" # macOS
    fi
    diff \
        <(cd "${1%/}" && find . -type f -print0 | LC_ALL=C sort -z | xargs -0 $hash) \
        <(cd "${2%/}" && find . -type f -print0 | LC_ALL=C sort -z | xargs -0 $hash)
}
# ----------------------------------------------------------------------------------------------------------------- }}}2

# dirdiff: compare two trees byte for byte, ignoring permissions, owner and timestamps. --------------------------- {{{2
#   dirdiff <src/> <dst/>
# Silent exit 0 means identical; any output is a difference.
dirdiff() {
    if [ $# -ne 2 ]; then
        echo "Usage: dirdiff <src/> <dst/>" >&2
        return 2
    fi
    rsync -nci --checksum --no-perms --no-owner --no-group --no-times \
        --delete "${1%/}/" "${2%/}/"
}
# ----------------------------------------------------------------------------------------------------------------- }}}2

# dirdiff-strict: same as dirdiff, but permissions and timestamps must match as well. ----------------------------- {{{2
dirdiff-strict() {
    if [ $# -ne 2 ]; then
        echo "Usage: dirdiff-strict <src/> <dst/>" >&2
        return 2
    fi
    rsync -nci --checksum --delete "${1%/}/" "${2%/}/"
}
# ----------------------------------------------------------------------------------------------------------------- }}}2

# ic: show an image in WezTerm. HEIC is converted to PNG first, since WezTerm cannot render it. ------------------- {{{2
ic() {
    local target="$1"
    if [[ "${target:e:l}" == "heic" || "${target:l}" == *.heic ]]; then
        local tmpfile=$(mktemp).png
        sips -s format png "$target" --out "$tmpfile" >/dev/null 2>&1
        wezterm imgcat "$tmpfile"
        rm "$tmpfile"
    else
        wezterm imgcat "$target"
    fi
}
# ----------------------------------------------------------------------------------------------------------------- }}}2

# lc: print the absolute paths of the arguments (default $PWD) and copy them to the clipboard. -------------------- {{{2
#   -P resolves symlinks, -L keeps them (the default).
lc() {
    local -a phys logi
    zparseopts -D -- P=phys L=logi || return 1
    local -a paths
    if (( $#phys )); then
        paths=(${${@:-$PWD}:A})
    else
        paths=(${${@:-$PWD}:a})
    fi
    print -rl -- $paths
    print -rn -- ${(F)paths} | pbcopy
}
compdef _files lc
# ----------------------------------------------------------------------------------------------------------------- }}}2

# proxy: turn the http/https/all proxy environment variables on or off. ------------------------------------------- {{{2
proxy() {
    if [[ $1 == on ]]; then
        echo 'Proxy turned on for http, https and all'
        export https_proxy=http://10.0.1.4:6152
        export http_proxy=http://10.0.1.4:6152
        export all_proxy=socks5://10.0.1.4:6153
    elif [[ $1 == off ]]; then
        echo 'Proxy turned off for http, https and all'
        unset http_proxy
        unset https_proxy
        unset all_proxy
    else
        echo 'Usage: proxy [on|off]'
    fi
}
# ----------------------------------------------------------------------------------------------------------------- }}}2

# retry: rerun a command every second until it succeeds. ---------------------------------------------------------- {{{2
retry() {
    local cmd="$*"
    until eval "$cmd"; do
        echo "Retrying: $cmd"
        sleep 1
    done
}
# ----------------------------------------------------------------------------------------------------------------- }}}2

# set_acl_inherit: grant a user inherited full access to a directory on macOS. ------------------------------------ {{{2
# Everything created in it afterwards inherits the same access.
#   set_acl_inherit <user> <dir>
set_acl_inherit() {
    if [ "$#" -ne 2 ]; then
        echo "Usage:   set_acl_inherit <user> <dir>" >&2
        echo "Example: set_acl_inherit satou /Users/shio/Downloads" >&2
        return 1
    fi

    local target_user="$1"
    local target_dir="$2"

    if [ ! -d "$target_dir" ]; then
        echo "No such directory: $target_dir" >&2
        return 1
    fi

    sudo chmod -R +a "$target_user allow read,write,execute,delete,append,readattr,writeattr,readextattr,writeextattr,readsecurity,file_inherit,directory_inherit" "$target_dir"

    if [ $? -eq 0 ]; then
        echo "Granted $target_user inherited access to $target_dir"
    else
        echo "Failed to set the ACL; check that you have sudo rights" >&2
    fi
}
# ----------------------------------------------------------------------------------------------------------------- }}}2

# lctl: launchctl wrapper for the gui/$UID domain. ---------------------------------------------------------------- {{{2
#
# Usage:
#   lctl reload    1b2c.aphrissa            # bootout + bootstrap by label
#   lctl print     1b2c.aphrissa            # dump job state
#   lctl kickstart 1b2c.aphrissa            # run now
#   lctl bootout   1b2c.aphrissa
#   lctl bootstrap 1b2c.aphrissa            # label form, resolves to ~/Library/LaunchAgents/<label>.plist
#   lctl bootstrap /abs/path/to/foo.plist   # path form (any arg containing "/")
#   lctl <anything-else>                    # falls through to raw launchctl
lctl() {
    local domain=gui/$UID
    local agents=$HOME/Library/LaunchAgents
    case $1 in
        bootstrap|load)
            local plist=$2
            [[ $plist == */* ]] || plist=$agents/${plist%.plist}.plist
            launchctl bootstrap $domain "$plist"
            ;;
        bootout|unload)
            launchctl bootout $domain/"$2"
            ;;
        reload)
            launchctl bootout $domain/"$2" 2>/dev/null
            launchctl bootstrap $domain "$agents/$2".plist
            ;;
        print|kickstart|start|stop|enable|disable)
            launchctl "$1" $domain/"$2"
            ;;
        *)
            launchctl "$@"
            ;;
    esac
}

# _lctl: completion for lctl.
_lctl() {
    local -a subs
    subs=(
        'bootstrap:load a plist by label (or path if arg contains /)'
        'bootout:unload a job by label'
        'reload:bootout + bootstrap in one step (idempotent)'
        'print:dump job state'
        'kickstart:trigger job to run now'
        'enable:allow job to run'
        'disable:prevent job from running'
        'start:legacy start'
        'stop:legacy stop'
        'kill:send signal to job'
        'list:list loaded jobs'
    )
    if (( CURRENT == 2 )); then
        _describe 'subcommand' subs
        return
    fi
    case $words[2] in
        bootstrap|bootout|reload|print|kickstart|start|stop|enable|disable|kill|load|unload)
            local -a labels
            labels=($HOME/Library/LaunchAgents/*.plist(N:t:r))
            _describe 'label' labels
            ;;
    esac
}
compdef _lctl lctl
# ----------------------------------------------------------------------------------------------------------------- }}}2

# ----------------------------------------------------------------------------------------------------------------- }}}1

[ -f ~/.private_rc ] && . ~/.private_rc

# vim: set fdm=marker fdl=1 tw=120:
