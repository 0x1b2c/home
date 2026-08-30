# Shell snippets shipped by other programs. The test for what belongs here:
# someone else wrote it and told you to paste it into your shell config.
# Everything is guarded, so a machine that lacks the tool simply skips it.

[[ -x $(which starship) ]] && eval "$(starship init zsh)"
[[ -x $(which mise) ]] && eval "$(mise activate zsh)"
[[ -x $(which zoxide) ]] && eval "$(zoxide init zsh)"

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
[ -s ~/.bun/_bun ] && source ~/.bun/_bun
[ -f ~/.config/broot/launcher/bash/br ] && source ~/.config/broot/launcher/bash/br
[ -f ~/.openclaw/completions/openclaw.zsh ] && source ~/.openclaw/completions/openclaw.zsh
