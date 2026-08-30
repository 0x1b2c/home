# Loader only. Same arrangement as ~/.zshrc: seeded once, then local.
#
# PATH is built here rather than in .zshenv because macOS runs path_helper from
# /etc/zprofile, immediately before this file, and it reorders whatever PATH it
# is given. This is the first hook that survives.
source ~/.zsh/paths.zsh
