# 1. 基础设置
HISTFILE="$HOME/.zsh_history"
HISTSIZE=10000000        # 内存中保留的行数
SAVEHIST=10000000        # 文件中保存的行数

# 2. 核心模式：写入统一，运行时隔离
setopt INC_APPEND_HISTORY        # 立即追加到文件 (防丢，且让其他 Tab 可读)
unsetopt SHARE_HISTORY           # 关闭实时共享。Tab 运行时互不干扰，启动时才读取历史。

# 3. 记录内容控制
setopt EXTENDED_HISTORY          # 记录时间戳和运行时长
setopt APPEND_HISTORY            # 确保是追加模式

# 4. 去重策略
setopt HIST_IGNORE_DUPS          # 忽略连续重复 (ls -l -> ls -l)
unsetopt HIST_IGNORE_ALL_DUPS    # 关掉强力去重，保留历史操作的完整顺序！

# 5. 视觉优化 (Magic Option)
# 虽然文件里有很多重复的命令，但按 Up 箭头或 Ctrl+R 搜索时，不要显示重复的
setopt HIST_FIND_NO_DUPS

# 6. 其他辅助
setopt HIST_IGNORE_SPACE         # 忽略空格开头
setopt HIST_VERIFY               # 展开历史时不立即执行
setopt HIST_REDUCE_BLANKS        # 删掉多余空格
setopt HIST_EXPIRE_DUPS_FIRST    # 只有当文件彻底存满(1000万行)要删老数据时，才优先删重复的

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

# Vi 风格键绑定
bindkey -v

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

if [[ -x `which starship` ]]; then
    eval "$(starship init zsh)"
else
    source ~/.zsh/theme.zsh
fi

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

if [[ $TERM == linux ]]; then
    fbterm -- tmux new -As rainux
fi

# 只在没有终端多路复用可用的地方自动进 tmux：SSH 会话，以及 WSL 的本地终端
# （$WSL_DISTRO_NAME 由 WSL 注入）。本机的 GUI 终端自己有标签页，不需要。
if [[ -z $TMUX && ( -n $SSH_TTY || -n $WSL_DISTRO_NAME ) ]]; then
    tmux new -As rainux
fi

if [[ -z $SSH_AUTH_SOCK ]]; then
    eval `ssh-agent`
fi
