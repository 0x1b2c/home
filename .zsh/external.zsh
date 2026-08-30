# Shell snippets shipped by other programs. The test for what belongs here:
# someone else wrote it and told you to paste it into your shell config.
# Everything is guarded, so a machine that lacks the tool simply skips it.
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

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
[ -s ~/.bun/_bun ] && source ~/.bun/_bun
[ -f ~/.config/broot/launcher/bash/br ] && source ~/.config/broot/launcher/bash/br
[ -f ~/.openclaw/completions/openclaw.zsh ] && source ~/.openclaw/completions/openclaw.zsh
