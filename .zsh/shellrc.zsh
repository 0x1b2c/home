# The reloadable half of the shell config. Everything here must be safe to
# run again at any moment: aliases, functions, and absolute assignments
# only. Nothing that accumulates, no setopt, no bindkey, no compinit.
# That invariant is what makes reload_shellrc work.
alias reload_shellrc='source ~/.zsh/shellrc.zsh'

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
    alias wicd='wicd-curses'
fi
# ----------------------------------------------------------------------------------------------------------------- }}}2

# Extra ----------------------------------------------------------------------------------------------------------- {{{2
if [[ -x $(which eza) ]]; then
    alias ls='eza --binary --color-scale=all --hyperlink --icons=auto'
    alias lsa='ls --absolute=on --hyperlink'
elif [[ $OSTYPE == darwin* ]]; then
    alias ls='ls -GFh'
else
    alias ls='ls --color -hF --show-control-chars'
fi

if [[ -x $(which bat) ]]; then
    alias cat='bat'
    alias less='bat'
else
    alias less='less -r'
fi

[[ -x $(which curlie) ]] && alias curl='curlie'
[[ -x $(which dog) ]] && alias dig='dog'
[[ -x $(which mongosh) ]] && alias mongo='mongosh'
[[ -x $(which wget2) ]] && alias wget='wget2'
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
# ANDROID_HOME, BUN_INSTALL, GOPATH are now in ~/.shell_paths
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

[ -f ~/.shell_paths ] && source ~/.shell_paths
# ----------------------------------------------------------------------------------------------------------------- }}}1

# Functions ------------------------------------------------------------------------------------------------------- {{{1
#
function dash() {
    local target
    # 用 grep 物理拦截注释行和空行，只把纯净的数据流放给 fzf
    target=$(grep -vE '^\s*(#|$)' ~/.projects | fzf --prompt="⚡️ 项目控制台 > " --delimiter="|" --with-nth=1,2)

    if [[ -n "$target" ]]; then
        # 提取路径并物理跳转 (触发 zoxide 底层计分)
        local dir=$(echo "$target" | awk -F '|' '{print $1}' | tr -d ' ')
        cd "$dir" || return

        # 瞬间清场，保持心流干净
        clear

        # 落地雷达侦测：判断是不是 Git 战场
        if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
            # 是 Git 仓库：高亮打印目录名，并输出极简状态
            echo -e "\033[1;32m[🎯 项目已切入: $(basename "$PWD")]\033[0m"
            git status -sb
            echo ""
        else
            # 普通目录：低调提示
            echo -e "\033[1;34m[📁 目录已切入: $(basename "$PWD")]\033[0m\n"
        fi
    fi
}

if [[ -x $(which delta) ]]; then
    diff() {
        command diff -ur "$@" | delta
        return $pipestatus[1]
    }
    compdef _diff diff
fi

# 用 sha256 对比两个目录，零写入零删除，只读
# 用法: dirdiff a/ b/
# 无输出 = 完全一致；有 < / > 行 = 那些文件不一致或单边存在
dirdiffs() {
    [ $# -eq 2 ] || {
        echo "usage: dirdiff <a> <b>" >&2
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

# 对比两个目录的内容是否字节级一致（忽略权限/属主/时间）
# 用法: dirdiff src/ dst/
# 静默退出 0 = 内容完全一致；有输出 = 有差异
dirdiff() {
    if [ $# -ne 2 ]; then
        echo "usage: dirdiff <src/> <dst/>" >&2
        return 2
    fi
    rsync -nci --checksum --no-perms --no-owner --no-group --no-times \
        --delete "${1%/}/" "${2%/}/"
}

# 严格版：连权限/时间也要一致
dirdiff-strict() {
    if [ $# -ne 2 ]; then
        echo "usage: dirdiff-strict <src/> <dst/>" >&2
        return 2
    fi
    rsync -nci --checksum --delete "${1%/}/" "${2%/}/"
}

ic() {
    local target="$1"
    # 检查文件后缀是不是 heic (忽略大小写)
    if [[ "${target:e:l}" == "heic" || "${target:l}" == *.heic ]]; then
        # 在系统的临时目录建一个 png 文件
        local tmpfile=$(mktemp).png
        # 调用 macOS 原生 sips 极速转码
        sips -s format png "$target" --out "$tmpfile" >/dev/null 2>&1
        # 用 WezTerm 渲染
        wezterm imgcat "$tmpfile"
        # 阅后即焚
        rm "$tmpfile"
    else
        # 其他格式直接渲染
        wezterm imgcat "$target"
    fi
}

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

proxy() {
    if [[ $1 == on ]]; then
        echo http/https/all proxy turned on
        export https_proxy=http://127.0.0.1:6152
        export http_proxy=http://127.0.0.1:6152
        export all_proxy=socks5://127.0.0.1:6153
    elif [[ $1 == off ]]; then
        echo http/https/all proxy turned off
        unset http_proxy
        unset https_proxy
        unset all_proxy
    else
        echo 'Usage: proxy [on|off]'
    fi
}

retry() {
    local cmd="$*"
    until eval "$cmd"; do
        echo "retrying: $cmd"
        sleep 1
    done
}

set_acl_inherit() {
    # 检查参数数量
    if [ "$#" -ne 2 ]; then
        echo "用法: set_acl_inherit <受益用户名> <目标目录>"
        echo "示例: set_acl_inherit satou /Users/shio/Downloads"
        return 1
    fi

    local target_user="$1"
    local target_dir="$2"

    # 检查目录是否存在
    if [ ! -d "$target_dir" ]; then
        echo "错误: 目录「$target_dir」不存在。"
        return 1
    fi

    # 执行 ACL 授权
    sudo chmod -R +a "$target_user allow read,write,execute,delete,append,readattr,writeattr,readextattr,writeextattr,readsecurity,file_inherit,directory_inherit" "$target_dir"

    # 验证执行结果
    if [ $? -eq 0 ]; then
        echo "成功: 已为「$target_user」在「$target_dir」配置完毕 ACL 继承规则。"
    else
        echo "失败: 配置 ACL 规则时出错，请检查是否拥有 sudo 权限。"
    fi
}

# launchctl on macOS only.
# ─── launchctl wrapper (only for gui/$UID domain) ──────────────
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

# ─── completion for lctl ───────────────────────────────────────
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
# ----------------------------------------------------------------------------------------------------------------- }}}1

[ -f ~/.private_rc ] && . ~/.private_rc

# vim: set fdm=marker fdl=1 tw=120:
