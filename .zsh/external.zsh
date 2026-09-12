# Shell snippets shipped by other programs. The test for what belongs here:
# someone else wrote it and told you to paste it into your shell config.
# Everything is guarded, so a machine that lacks the tool simply skips it.
#
# Ask the tool for its snippet rather than sourcing a file it generated once.
# A generated file freezes the paths of the machine that wrote it and then
# fails silently, since every line in it is guarded.
#
# Loaded from rc.zsh, and it has to stay before the prompt fallback there:
# rc.zsh decides whether to load theme.zsh by asking whether anything in here
# already claimed the prompt.

# LS_COLORS, read by ls, eza and the completion menu. GNU coreutils names it
# dircolors; the homebrew build on macOS prefixes every tool with g.
(( $+commands[dircolors] )) && eval "$(dircolors -b)"
(( $+commands[gdircolors] )) && eval "$(gdircolors -b)"

(( $+commands[starship] )) && eval "$(starship init zsh)"
(( $+commands[mise] )) && eval "$(mise activate zsh)"
(( $+commands[zoxide] )) && eval "$(zoxide init zsh)"
(( $+commands[fzf] )) && eval "$(fzf --zsh)"
(( $+commands[broot] )) && eval "$(broot --print-shell-function zsh)"
(( $+commands[survey] )) && eval "$(survey completions zsh)"

# No generator to ask. Both are rewritten by their own installer and name no
# absolute path.
[ -s ~/.bun/_bun ] && source ~/.bun/_bun
[ -f ~/.openclaw/completions/openclaw.zsh ] && source ~/.openclaw/completions/openclaw.zsh

# Completions, which these tools print only on demand. Written to a cache on
# fpath instead of evaluated at startup: uv alone is 6000 lines and costs 78ms
# to evaluate, while the block below costs 0.15ms, because autoload records the
# name and defers reading the file until the completion is first used.
# Regenerated once the tool is newer than the file it produced.
#
# fpath may be extended after compinit, as long as compdef names the function.
() {
    local d=${XDG_CACHE_HOME:-$HOME/.cache}/zsh/completions
    local tool fn cmd
    [[ -d $d ]] || mkdir -p $d
    fpath=($d $fpath)
    for tool fn cmd in \
        uv     _uv     'uv generate-shell-completion zsh' \
        rustup _rustup 'rustup completions zsh' \
        rustup _cargo  'rustup completions zsh cargo'
    do
        (( $+commands[$tool] )) || continue
        [[ -s $d/$fn && $d/$fn -nt $commands[$tool] ]] || eval $cmd > $d/$fn
        autoload -Uz $fn
        compdef $fn ${fn#_}
    done
}
