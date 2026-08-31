Installation
============

    git clone git@github.com:0x1b2c/home.git ~/home
    ~/home/install

`install` is a symlink to `link.py`. With no argument it is a dry run: it lists
everything it would do and everything standing in its way, and changes nothing.

    ~/home/install --fix

carries out exactly what the dry run listed and nothing besides. It creates
what is missing and brings `$HOME` into agreement with the repository as far as
it safely can.

It never moves, deletes, overwrites or alters anything that holds content of
its own: not a file, not a directory, not a permission bit. The one thing it
removes is a symlink pointing into this repository, which holds nothing of its
own. Whatever it cannot handle on those terms is listed with what to do about
it and left to you; clear it by hand and run `--fix` again. Running it any
number of times is safe.

The exit status is zero only when nothing is left outstanding, so a
provisioning script can act on it. `--verbose` also lists what is already
correct.

Note: `.gitconfig` carries a name, an email address and a signing key. Change
them.
