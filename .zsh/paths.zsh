# Everything that decides PATH, in one place. Sourced from ~/.zprofile so that
# it runs after macOS's /etc/zprofile path_helper, which reorders PATH and would
# otherwise push these entries behind the system ones.

# Homebrew, where this machine has it. It has to run before the array below:
# its shellenv delegates to path_helper, which rewrites the whole PATH, so
# anything set first would come back reordered behind the system entries. It
# also puts brew's completions on fpath, which hand-written entries would miss.
for _brew in /opt/homebrew/bin/brew /usr/local/bin/brew \
             /home/linuxbrew/.linuxbrew/bin/brew; do
    [[ -x $_brew ]] && { eval "$($_brew shellenv)"; break }
done
unset _brew

# Root directories that the entries below are derived from, and that the tools
# themselves read.
export ANDROID_HOME="$HOME/android-sdk"
export BUN_INSTALL="$HOME/.bun"
export GOPATH="$HOME/.go"

# PATH and path are one value under two names, tied by zsh: the exported scalar
# and its array view. The uniqueness flag only acts on the name being assigned,
# so both have to carry it or duplicates slip in through the unmarked one.
typeset -U PATH path

# The union of every machine's directories, in priority order. Each comment says
# which tool installs there, so a line can be retired when its tool is.
path=(
    "$HOME/bin"                             # hand-written scripts
    "$HOME/.local/bin"                      # the user-level /usr/local/bin: pip --user,
                                            # uv, and most curl-into-sh installers
    "$HOME/.cargo/bin"                      # cargo install
    "$BUN_INSTALL/bin"                      # bun
    "$HOME/.cache/lm-studio/bin"            # LM Studio's lms
    "$HOME/.antigravity/antigravity/bin"    # Antigravity
    "$GOPATH/bin"                           # go install
    "$ANDROID_HOME/tools"                   # Android SDK
    "$ANDROID_HOME/platform-tools"
    "/usr/local/sbin"
    "/usr/local/bin"
    $path                                   # brew, system, whatever came before
)

# Drop what this machine does not actually have, so the list above can stay the
# union of every machine without each one carrying the others' dead entries.
path=( ${^path}(N-/) )

# Trust ./bin and ./node_modules/.bin only in repositories marked with .git/safe.
# Relative and resolvable only inside such a repository, so it has to be added
# after the prune above, which would otherwise delete both entries.
path=(.git/safe/../../bin .git/safe/../../node_modules/.bin $path)

# lspath: print PATH one entry per line, numbered.
lspath() {
    echo "$PATH" | tr ':' '\n' | nl
}
