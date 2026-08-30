# Read by every zsh, interactive or not, so that scripts and GUI programs
# started from a shell see the same environment.  Keep it cheap: Veil gives
# `zsh -l -c env` five seconds before falling back to launchd's bare PATH.

# What this machine is.  Absent on purpose almost everywhere: a plain clone
# is the minimal configuration, and only a machine that says otherwise gets
# the full one.  Never holds secrets; those stay in ~/.private_rc.
() {
    local f=${XDG_CONFIG_HOME:-$HOME/.config}/machine.env
    [[ -r $f ]] || return
    setopt localoptions allexport
    source $f
}
export MACHINE_ROLE=${MACHINE_ROLE:-minimal}
