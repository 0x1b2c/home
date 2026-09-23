# Shell snippets shipped by other programs. The test for what belongs here:
# someone else wrote it and told you to paste it into your shell config.
# Everything is guarded, so a machine that lacks the tool simply skips it.
#
# The guard is -x on the resolved path, not $+commands. $commands is built by
# listing the PATH directories, so it holds every name found there whether or
# not it can run: on a2 a dangling ~/.cargo/bin/rustup, left pointing at a
# removed /usr/local/bin/rustup-init, passed $+commands and every new shell
# then printed "command not found". -x follows the link and fails.
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
[[ -x $commands[dircolors] ]] && eval "$(dircolors -b)"
[[ -x $commands[gdircolors] ]] && eval "$(gdircolors -b)"

[[ -x $commands[starship] ]] && eval "$(starship init zsh)"
[[ -x $commands[mise] ]] && eval "$(mise activate zsh)"
[[ -x $commands[zoxide] ]] && eval "$(zoxide init zsh)"
[[ -x $commands[fzf] ]] && eval "$(fzf --zsh)"
[[ -x $commands[broot] ]] && eval "$(broot --print-shell-function zsh)"
[[ -x $commands[survey] ]] && eval "$(survey completions zsh)"

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
        [[ -x $commands[$tool] ]] || continue
        [[ -s $d/$fn && $d/$fn -nt $commands[$tool] ]] || eval $cmd > $d/$fn
        autoload -Uz $fn
        compdef $fn ${fn#_}
    done

    # Hand-written completion linked here by ~/Agentic/Skills/link.sh; the claude
    # CLI ships none, so there is no generator for it.
    [[ -f $d/_claude ]] && { autoload -Uz _claude; compdef _claude claude }
}
