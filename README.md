Installation
============

    git clone git@github.com:0x1b2c/home.git ~/home
    ~/home/install

`install` is a symlink to `link.py`. With no argument it audits: it lists
everything it would do and everything standing in its way, and changes nothing.

    ~/home/install --fix

creates what is missing, and only that. Most entries become symlinks into the
repository; the directories in `CONTAINERS` are created as real ones so they
can hold local files beside the linked ones, and the shell loaders in `SEEDS`
are copied once, so that installers appending to them write to this machine
rather than into the repository.

`--verbose` adds the entries that are already correct and the ones excluded by
name. It changes nothing else, the exit status included.

Nothing already in `$HOME` is ever moved, deleted, overwritten or altered,
permissions included. Whatever occupies a path the repository wants is listed
with what to do about it and left for you to clear by hand; run `--fix` again
afterwards. Entries below a directory that is not a real one yet are listed as
waiting on it. A fault in the repository itself -- a symlink pointing at
nothing, a name in `CONTAINERS` that is not a directory -- is named as such,
since there is nothing in `$HOME` to clear.

A copied seed keeps whatever installers append below it, but the repository's
own copy has to remain its head. Once it no longer is, the difference is shown
and left for you to reconcile.

What gets created takes its permissions from this machine's umask and never
from the repository copy's; `.ssh` and `.gnupg` are created 0700.

The exit status is zero only when nothing is left outstanding, so a
provisioning script can act on it.

Note: `.gitconfig` carries a name, an email address and a signing key. Change
them.
