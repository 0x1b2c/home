#!/usr/bin/env python3
"""Keep the dotfile symlinks in $HOME pointing at this repository.

The script only ever creates what is absent, with one exception: it may remove
a symlink whose target lies inside this repository, because such a link holds
no content of its own: the content is in the repository, and unlinking it
loses nothing. Nothing else is ever touched. No regular file, no directory and
no symlink pointing anywhere outside the repository is moved, deleted, renamed,
overwritten or chmodded: getting that right under every partial failure,
interruption and filesystem boundary turned out to cost far more than it saved,
and the fallback (you move the thing aside yourself) is a single command you
can see the result of.

So findings come in three kinds. Ones --fix carries out: writing where nothing
exists, or clearing a link into the repository first. Ones it only names,
because $HOME holds something at that path that only you can value. And ones
where the fault is in the repository itself, with nothing in $HOME to clear.
Each of the last two says what to do about it.

A second, shorter pass looks the other way down the link, for entries in $HOME
that point into this repository at something the repository no longer has. The
forward walk cannot see those: it enumerates the repository, and they are
exactly the paths the repository stopped having.

An entry that is already as it should be is counted as verified rather than
passed over in silence, so a run can say how much it checked and not only what
it found. --verbose prints those too, and the entries skipped by EXCLUDES.
"""

import argparse
import difflib
import os
import sys
from pathlib import Path

# ===================== Explicit configuration =====================
# The sets that select entries are compared against the entry's path relative
# to the repository root, so a nested entry such as .config/nvim works in any
# of them. EXCLUDES additionally matches a bare name at any depth, because junk
# like .DS_Store turns up anywhere; the others always name one specific entry.
# BAD_LINK_PATTERNS is different in kind: it selects nothing, it only changes
# how an existing link's target is described.

# 1. Names skipped entirely, whatever they are.
EXCLUDES = {
    ".git",
    ".gitignore",
    ".DS_Store",
    "link.py",
    # The alias this script is invoked through. Excluded by name like link.py
    # itself, or ~/install would appear on every machine.
    "install",
    "README.md",
    "__pycache__",
    # Clones of separate repositories that happen to sit in this working tree,
    # untracked and each carrying its own .git, so neither is this repository's
    # to manage. What sits at the matching path in $HOME differs between them
    # and is deliberately not the script's business either: ~/.config/nvim is
    # its own newer clone, ~/.config/nvim-nvchad is a link back into this tree.
    ".config/nvim",
    ".config/nvim-nvchad",
    # Syncthing's own directories and a one-off backup; not dotfiles.
    ".stfolder",
    ".stversions",
    ".stignore",
}

# 2. Containers: these must be real directories under $HOME, not symlinks.
# The script descends into them and links their immediate children one by one,
# so a directory can hold both repo-managed entries and local ones.
CONTAINERS = {
    ".config",
    ".ssh",
    ".zsh",
    # Listed ahead of the directory existing in the repo. Should one ever
    # appear, the default rule would make ~/.gnupg a symlink to it, which is
    # the one arrangement gpg-agent will not accept.
    ".gnupg",
    "bin",
}

# Containers this script creates with mode 0700 instead of leaving them to the
# umask. git records no directory modes, so a clone's own .ssh is whatever the
# umask of whoever cloned it produced, and mirroring that would launder an
# accident into $HOME.
#
# What the mode covers is narrower than the name suggests: only entries created
# directly inside the container afterwards, by you or by another program. It
# does nothing for what this script puts there. A symlink is checked against the
# file it resolves to, so ~/.ssh/config is exactly as readable as the repository
# copy behind it, and this repository is a public one. Anything whose
# confidentiality matters does not belong in it at all.
PRIVATE_CONTAINERS = {
    ".ssh",
    ".gnupg",
}

# 3. Seeds: copied from the repo as a REAL file when missing, and never
# rewritten afterwards. Once the copy exists it is the machine's own file,
# which is the whole point: third-party installers (cargo,
# bun, broot) append to the end of ~/.zshrc, ~/.zshenv and ~/.zprofile, and as
# symlinks those appends would land in the repo and reach every machine. The
# repo versions are one-line loaders, and the configuration they load is still
# symlinked.
SEEDS = {
    ".zshrc",
    ".zshenv",
    ".zprofile",
}

# 4. Substrings marking a symlink as left over from an older layout. Matched
# anywhere in the target, not just at the start: these links are usually
# absolute, so the interesting directory sits in the middle of the path.
# This only changes how a link is described, never what happens to it, but a
# link that already resolves correctly is still named, so keep these specific.
# A pattern is ignored for any entry whose own correct target contains it,
# since there it cannot tell a stale link from the right one. See the check.
BAD_LINK_PATTERNS = [
    "Dropbox",
]
# ==================================================================

HOME = Path.home()

# The source is where this script lives, never the working directory. Taking
# the latter would make any directory the caller happened to be in look like
# the dotfiles repository, and from $HOME every entry would be its own target.
SRC = Path(__file__).resolve().parent

# Colour is for reading, not for parsing: drop it when stdout is not a
# terminal, and honour the NO_COLOR convention, which asks for a non-empty
# value: NO_COLOR= set to nothing means the same as unset.
COLOR = sys.stdout.isatty() and not os.environ.get("NO_COLOR")


def paint(text, code):
    return f"\033[{code}m{text}\033[0m" if COLOR else text


# Every printed row uses these two columns, so a --verbose listing puts the
# findings and the verified entries in the same tag column instead of
# interleaving two layouts. A tag longer than the field pushes its own row
# right rather than widening every other one.
TAG_WIDTH = 21
PATH_WIDTH = 26


def home_display(rel_path):
    """How a $HOME-side path is shown: the path the finding is actually about.

    The walk enumerates the repository, so its relative paths read as though
    the trouble were in the repository. Nearly every finding is about the
    other side, and a bare .hammerspoon leaves the reader guessing which of
    the two it means.
    """
    return f"~/{rel_path}"


def row(tag, code, rel_path, trailing):
    """One listing line: a bracketed tag, the path, then whatever follows.

    The brackets are punctuation, not part of the label: colouring only the
    word keeps a column of tags scannable without the delimiters glowing. The
    padding is computed on the uncoloured text, since the escapes have no
    width on screen but plenty in the string.
    """
    tagged = f"[{paint(tag, code)}]"
    pad = TAG_WIDTH + (len(tagged) - len(tag) - 2)
    # The path is padded even when nothing follows it here: report() appends
    # its own annotation afterwards, and a column that only sometimes lines up
    # is worse than none. rstrip takes the padding back off when it turns out
    # to be trailing whitespace.
    return f"{tagged.ljust(pad)} {str(rel_path).ljust(PATH_WIDTH)} {trailing}".rstrip()


CREATE = "create"  # writes where nothing is; --fix carries it out
MANUAL = "manual"  # $HOME already holds something here; yours to clear
REPO = "repo"  # the fault is in the repository; nothing in $HOME to clear

# Colour by how much is at stake, not by which branch found it.
STYLE = {
    "link missing": ("32", CREATE),  # green
    "container missing": ("32", CREATE),
    "seed missing": ("32", CREATE),
    # Yellow: a link is in the way. Clearing it costs nothing but the link, so
    # when it points into the repository these are promoted to CREATE at the
    # call site and printed green; the class here is the one they keep when it
    # points somewhere only you can judge.
    "wrong target": ("33", MANUAL),
    "stale link": ("33", MANUAL),
    "seed is a link": ("33", MANUAL),
    "container is a link": ("33", MANUAL),
    # Red: real content is in the way, and only you know what it is worth.
    "in the way": ("31", MANUAL),
    "seed is a directory": ("31", MANUAL),
    "seed is not a file": ("31", MANUAL),
    "seed diverged": ("31", MANUAL),
    "seed unreadable": ("31", MANUAL),
    "container is a file": ("31", MANUAL),
    "container is not a directory": ("31", MANUAL),
    "container is not private": ("31", MANUAL),
    # Magenta: $HOME is fine and holds nothing to clear. Both are repaired in
    # the repository, so no container above them is what they wait on.
    "container source is not a directory": ("35", REPO),
    "broken source": ("35", REPO),
}

# to_create is what --fix would carry out and an audit only lists. It is
# counted apart from the rest because on a fresh machine it is the whole of the
# work and none of it is yours to do by hand. skipped, blocked and repo are
# kept apart in turn: skipped is a finding you can go and deal with now in
# $HOME, blocked is one that cannot even be looked at until the container above
# it is a real directory, and repo is one where $HOME holds nothing at all and
# the repository is what needs editing. Folding the last into skipped told the
# reader to clear a path that does not exist.
#
# examined counts every entry that reached a decision, and BUCKETS partition it
# exactly: each entry lands in one and only one. The summary checks that and
# says so if it ever fails to hold, because a check that cannot account for its
# own findings should not print a total as though it could. excluded stays out
# of the total, since those entries were never examined at all.
BUCKETS = ("applied", "to_create", "skipped", "blocked", "repo", "failed", "verified")

counts = {
    "applied": 0,
    "to_create": 0,
    "skipped": 0,
    "blocked": 0,
    "repo": 0,
    "failed": 0,
    "verified": 0,
    "examined": 0,
    "excluded": 0,
}

# Which containers the blocked findings are waiting on, so the summary can name
# the one they share instead of saying "a container".
blockers = set()

# Every $HOME path the forward walk reached a decision about, excluded ones
# included. The reverse scan below skips these: the walk has already said what
# it thinks of them, and an excluded entry is one this script does not manage
# from either direction.
visited = set()

# The reverse scan is counted apart from the walk. Its entries are not in the
# repository, so they are not among the examined ones and must not enter that
# accounting. Folding them in would make the parts stop adding up to a total
# taken over a different set.
scan_counts = {
    "to_remove": 0,
    "removed": 0,
    "verified": 0,
    "left_empty": 0,
    "failed": 0,
}

# Set from --verbose. It adds output and changes no decision and no count.
VERBOSE = False

# The entry being handled, so an interrupt can say where it stopped.
current = {"entry": None}


def report(tag, rel_path, detail, fix, pending=None, klass=None):
    """Print one finding and say whether this run should act on it.

    Only findings this run leaves alone are counted here. The ones it acts on
    are counted by applied() or failed() once the action has returned, so the
    summary never reports an intention that then failed.

    A MANUAL or REPO finding is never acted on. Each carries its own
    instruction in `detail`, so no flag is suggested for it: there is none that
    would help.

    `klass` overrides the tag's usual class. The three link-shaped findings
    take either one depending on where the link points: into the repository,
    where clearing it loses nothing and --fix does so, or outside it, where
    only you know what it is worth. The colour then follows the class rather
    than the tag, so a row tells the reader what will happen to it instead of
    which branch found it; a promoted finding is green like every other thing
    --fix carries out, and does not sit yellow among the work left to do.
    """
    code, default_klass = STYLE[tag]
    # The two REPO tags are the only findings about the repository side, so
    # they keep the plain relative path; everything else is shown as ~/ ...
    shown = rel_path if default_klass is REPO else home_display(rel_path)
    if klass is None:
        klass = default_klass
    elif klass is CREATE and default_klass is not CREATE:
        code = "32"
    acting = klass is CREATE and fix and pending is None

    # Assembled before printing, so the whole line goes through row() and
    # lands in the same columns as every other one.
    parts = [f"({detail})"] if detail else []

    if pending is not None:
        # Yellow, the colour of the summary row these are counted in: a
        # finding must not change colour between the listing and the total.
        parts.append(paint(f"Waiting on {pending}.", "33"))
        counts["blocked"] += 1
        blockers.add(pending)
    elif not acting:
        if klass is CREATE:
            parts.append(paint("Needs --fix.", "2"))
            counts["to_create"] += 1
        elif klass is REPO:
            counts["repo"] += 1
        else:
            counts["skipped"] += 1

    print(row(tag, code, shown, "  ".join(parts)))
    return acting


def applied(message):
    counts["applied"] += 1
    print(paint(f"  {message}", "2"))


def failed(message):
    counts["failed"] += 1
    print(paint(f"  {message}", "1;31"))


def verified(tag, rel_path, detail):
    """Record an entry that is already as it should be.

    Silent unless --verbose, where it states the property that was checked
    rather than a bare ok: what the run confirmed is the useful half.
    """
    counts["verified"] += 1
    if VERBOSE:
        print(row(tag, "34", home_display(rel_path), paint(detail, "2")))


def excluded(rel_path, why):
    """Record an entry EXCLUDES kept out of the walk.

    Never examined, so it stays out of the examined total; printed only under
    --verbose, where "why was this one not touched" is the usual question.

    The path is shown without the ~/ prefix the other rows carry. What is
    excluded is the repository entry; the point of excluding it is that no
    counterpart in $HOME is ever created, so naming one would be a fiction.
    """
    counts["excluded"] += 1
    if VERBOSE:
        print(row("excluded", "2", str(rel_path), paint(why, "2")))


# How much of the local seed to read beyond the repository copy: enough for the
# diff to carry trailing context, and a bound on the read, since a seed's local
# tail has no size limit and reading it whole put ten times its size in memory.
DIFF_MARGIN = 4096

# Lines of local content shown after the compared head, so a divergence at the
# very end of it still has something underneath.
DIFF_CONTEXT_LINES = 3


def seed_head_matches(repo_bytes, head):
    """True when the local seed still begins with the repository copy.

    Compared as bytes and only over the head: everything past it is what
    installers appended, which belongs to the machine and is never a difference.

    The newline clause is why this is not a plain startswith. A repository seed
    whose last line carries no terminating newline can never be a byte prefix of
    a local copy that has been appended to, because the append begins on a fresh
    line and the local file therefore has a newline the repository one lacks.
    Accepting exactly that one newline keeps such a seed from being reported as
    diverged on every run for ever, while still refusing a local copy whose
    first line merely happens to start with the same characters.
    """
    if not head.startswith(repo_bytes):
        return False
    if repo_bytes.endswith(b"\n"):
        return True
    rest = head[len(repo_bytes) :]
    return rest == b"" or rest.startswith(b"\n")


def print_seed_diff(item, home_target, repo_bytes, head):
    """Show where the local copy stopped agreeing with the repository one.

    Only the head is compared, so only the head is shown. Diffing against the
    whole local file rendered every legitimately appended installer line as an
    addition and buried the real divergence beneath them.

    The colours below are the diff convention and not this script's scheme:
    inside a diff, green marks a line the local file has, which is the one
    thing the script will never write.
    """
    repo_lines = repo_bytes.decode(errors="replace").splitlines(keepends=True)
    local_lines = head.decode(errors="replace").splitlines(keepends=True)
    if len(head) == len(repo_bytes) + DIFF_MARGIN and local_lines:
        # The read stopped at the margin, so the last line may be half of one.
        local_lines.pop()
    local_lines = local_lines[: len(repo_lines) + DIFF_CONTEXT_LINES]
    for raw in difflib.unified_diff(
        repo_lines, local_lines, fromfile=str(item), tofile=str(home_target)
    ):
        text = raw.rstrip("\n")
        if text.startswith(("---", "+++", "@@")):
            code = "2"
        elif text.startswith("+"):
            code = "32"
        elif text.startswith("-"):
            code = "31"
        else:
            code = None
        print(f"  {text}" if code is None else paint(f"  {text}", code))


def link_target(path):
    """What a symlink names: the raw text, and it made absolute and normalised.

    Never resolve(): that follows every link in the chain and would judge a
    link by where it eventually lands rather than by what it names. A link into
    the repository that the repository then points elsewhere is still a link
    into the repository, and one that names a path outside it is still outside
    however that path is later redirected.
    """
    actual = os.readlink(path)
    target = Path(actual)
    if not target.is_absolute():
        target = path.parent / target
    return actual, Path(os.path.normpath(target))


def inside_repo(target):
    """True when an already-normalised path lies at or under SRC.

    Compared by path components, not by string prefix: a sibling directory
    named home2 starts with the same characters as home and is not inside it.
    """
    return target == SRC or SRC in target.parents


def remove_repo_link(path):
    """Unlink a symlink that names a path inside the repository.

    The one thing this script removes, and the reason it is allowed to: such a
    link carries no content, only a direction, and the thing it points at is in
    the repository either way.

    Both halves of the precondition are re-established here rather than trusted
    from the caller's earlier look, since between the two the path could have
    become something else entirely. os.unlink refuses a directory, so even a
    check that somehow passed on one cannot take a tree down.
    """
    if not os.path.islink(path):
        raise OSError(f"{path} is no longer a symlink")
    _, target = link_target(path)
    if not inside_repo(target):
        raise OSError(f"{path} no longer points inside {SRC}")
    os.unlink(path)


def is_broken(item):
    """True when the repository entry points at nothing that exists."""
    return item.is_symlink() and not item.exists()


def link(home_target, item):
    # Point at the repository entry itself, not at what it resolves to. The
    # repo keeps symlinks of its own, and resolving would bypass them; the
    # indirection is the repo's to decide.
    home_target.parent.mkdir(parents=True, exist_ok=True)
    home_target.symlink_to(item)


def make_container(home_target, rel_path):
    """Create a container with an explicit mode, never an inherited one.

    mkdir()'s default takes the umask, and mirroring the repository directory
    would only launder the umask of whoever cloned it, since git records no
    directory modes. ~/.ssh created group- and world-readable is unusable to
    OpenSSH.

    The mode goes to mkdir rather than to a chmod afterwards. Two steps left a
    window in which a private container was world-readable, and left the
    directory at the umask mode for good if the run was interrupted inside it.
    No exist_ok either: a path that turned into a symlink between the check and
    this call now raises instead of being followed, so the mode can never land
    on whatever the link points at, outside $HOME.
    """
    mode = 0o700 if str(rel_path) in PRIVATE_CONTAINERS else 0o755
    os.mkdir(home_target, mode)


def tighten_private(home_target, rel_path):
    """Narrow a just-created private container if it came out wider than 0700.

    The umask can only clear bits from mkdir's mode, so this should not fire;
    it covers a filesystem that grants bits of its own, through an inherited
    ACL or similar. The chmod is safe here and nowhere else: this process
    created the directory a moment ago, so it cannot be a path that was already
    there, and it cannot be a link.
    """
    if str(rel_path) not in PRIVATE_CONTAINERS:
        return
    if os.stat(home_target).st_mode & 0o077:
        os.chmod(home_target, 0o700)


def copy_seed(item, home_target):
    """Write the repository copy to a path that must not already exist.

    O_EXCL rather than a plain open: it makes "never overwrites" a property of
    the write itself instead of a property of the absence check that preceded
    it. Those two are not one atomic step, and the very installers a seed
    exists to accommodate may be creating ~/.zshrc in the same window.

    0o666 leaves the result to the machine's umask. Copying the repository
    file's mode instead (which is what shutil.copy2 does, metadata and all)
    carries the umask of whoever cloned the repository into $HOME, and ~/.zshrc
    is executed by every interactive shell.
    """
    data = item.read_bytes()
    fd = os.open(home_target, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o666)
    try:
        os.write(fd, data)
    finally:
        os.close(fd)


def audit_and_fix(current_dir, fix, pending=None, as_absent=False):
    """Walk one directory of the repository.

    `pending` names an ancestor that will still not be a real directory in
    $HOME when this run ends. Its children are listed anyway, so the whole of
    the outstanding work is visible, but nothing under it is acted on: writing
    there would either fail or land inside whatever the ancestor points at.

    `as_absent` carries the other half of that on its own. An audit over a
    container that is a link into the repository has to preview the children
    against the empty directory --fix would leave, not against what they look
    like through a link that is about to go; but they are not blocked, because
    the same run would clear the link and then handle them. Reading the child's
    real path here would resolve through the doomed link and find the
    repository's own files sitting in the way of themselves.
    """
    for item in sorted(current_dir.iterdir()):
        rel_path = item.relative_to(SRC)
        # Recorded before the exclusion test, so the reverse scan leaves alone
        # both what this walk handled and what it deliberately did not.
        visited.add(HOME / rel_path)
        if item.name in EXCLUDES or str(rel_path) in EXCLUDES:
            # Not descended into either: an excluded directory is excluded
            # whole, so its contents are never enumerated.
            excluded(rel_path, "not managed by this script")
            continue

        counts["examined"] += 1
        current["entry"] = rel_path
        home_target = HOME / rel_path

        # Under a pending ancestor, home_target does not describe the state a
        # fix would meet: it resolves through the ancestor's symlink, into a
        # directory that stops being there the moment the ancestor becomes a
        # real one. Preview the child as what it will be then, which is absent.
        if pending is not None or as_absent:
            is_link = False
            absent = True
        else:
            is_link = home_target.is_symlink()
            absent = not home_target.exists() and not is_link

        # Linking to a repository entry that points at nothing would give $HOME
        # a link to a missing path, and every later run would then read both
        # sides as equally absent and report nothing. Reported with pending
        # cleared: the fault is in the repository, so no container above it is
        # what this waits on.
        if is_broken(item):
            report(
                "broken source",
                rel_path,
                "points at nothing; fix it in the repository",
                fix,
            )
            continue

        # Seeds: supply a copy when missing, and leave an existing one alone.
        if str(rel_path) in SEEDS:
            if is_link:
                # A seed made a link by an older layout. Pointing into the
                # repository it holds nothing, so --fix clears it and writes
                # the copy; pointing anywhere else it is an arrangement of
                # yours and only named.
                actual, target = link_target(home_target)
                if inside_repo(target):
                    if report(
                        "seed is a link",
                        rel_path,
                        "a link into the repository, so nothing of yours is "
                        "here; --fix replaces it with a real file",
                        fix,
                        pending,
                        klass=CREATE,
                    ):
                        try:
                            remove_repo_link(home_target)
                            copy_seed(item, home_target)
                        except OSError as e:
                            failed(f"Replacing the link failed: {e}")
                        else:
                            applied("Replaced with a local copy.")
                else:
                    report(
                        "seed is a link",
                        rel_path,
                        f"points at {actual}, outside the repository, so it is "
                        "left alone; this has to be a real file of your own",
                        fix,
                        pending,
                    )
            elif absent:
                if report("seed missing", rel_path, None, fix, pending):
                    try:
                        copy_seed(item, home_target)
                        applied("Copied as a local file.")
                    except OSError as e:
                        failed(f"Copy failed: {e}")
            elif home_target.is_dir():
                report(
                    "seed is a directory",
                    rel_path,
                    "this has to be a real file; move the directory aside",
                    fix,
                    pending,
                )
            elif home_target.is_file():
                # Installers only ever append, so the repository copy must
                # still be the head of the local one. Anything else means the
                # loader itself has moved on in the repository while this
                # machine kept the old one. Silent drift, and exactly what a
                # seed's copy-once rule cannot catch by itself. Reported, never
                # rewritten: the tail below is this machine's and only you know
                # how the two should be reconciled.
                try:
                    repo_bytes = item.read_bytes()
                    with open(home_target, "rb") as fh:
                        head = fh.read(len(repo_bytes) + DIFF_MARGIN)
                except OSError as e:
                    # A tag of its own rather than a bare message. Printed
                    # without one it landed under the previous entry's finding
                    # and read as belonging to that path, and an audit that
                    # attempted nothing came out reporting a failure.
                    report(
                        "seed unreadable",
                        rel_path,
                        f"could not be read, so it is left alone: {e}",
                        fix,
                        pending,
                    )
                else:
                    if seed_head_matches(repo_bytes, head):
                        verified(
                            "seed verified",
                            rel_path,
                            "the repository's version is still its start",
                        )
                    else:
                        report(
                            "seed diverged",
                            rel_path,
                            "the repository's version is no longer the start of "
                            "this file; reconcile them yourself",
                            fix,
                            pending,
                        )
                        print_seed_diff(item, home_target, repo_bytes, head)
            else:
                # A socket, a fifo, a device node. Nothing legitimate puts one
                # at a seed path, and reading it to compare could block for
                # ever, so it is named rather than examined.
                report(
                    "seed is not a file",
                    rel_path,
                    "has to be a real file; move whatever is here aside",
                    fix,
                    pending,
                )
            continue

        if str(rel_path) in CONTAINERS:
            # Descending needs a directory to descend into. A name listed here
            # whose repository entry is a file used to raise NotADirectoryError
            # part-way through the walk.
            if not item.is_dir():
                # pending cleared for the same reason as a broken source: the
                # fault is in the repository, so no container above it is what
                # this waits on.
                report(
                    "container source is not a directory",
                    rel_path,
                    "a directory is expected here so its contents can be "
                    "linked one by one; make it one in the repository, or edit "
                    "link.py to stop treating it that way",
                    fix,
                )
                continue

            # ready means: by the time this run is over, $HOME holds a real
            # directory here. The children are previewed against that, so an
            # audit predicts what a --fix run does rather than describing a
            # state --fix is about to replace.
            ready = False
            # Set when this run will replace the container but has not done so
            # yet, which is only ever an audit: the children exist on disk
            # through the old link, and the state that matters is the one after.
            preview_absent = False
            if is_link:
                # Same reasoning as a seed that is a link: into the repository
                # it holds nothing and --fix clears it, and the directory that
                # replaces it is then ready for this run's own children.
                actual, target = link_target(home_target)
                if inside_repo(target):
                    if report(
                        "container is a link",
                        rel_path,
                        "a link into the repository, so nothing of yours is "
                        "here; --fix replaces it with a real directory",
                        fix,
                        pending,
                        klass=CREATE,
                    ):
                        try:
                            remove_repo_link(home_target)
                            make_container(home_target, rel_path)
                        except OSError as e:
                            failed(f"Replacing the link failed: {e}")
                        else:
                            applied("Replaced with a directory.")
                            ready = True
                            try:
                                tighten_private(home_target, rel_path)
                            except OSError as e:
                                print(
                                    paint(
                                        f"  Created, but its mode could not be "
                                        f"narrowed to 0700: {e}",
                                        "1;31",
                                    )
                                )
                    else:
                        # --fix would have cleared it, so an audit previews the
                        # children against the empty directory that would be
                        # here, rather than through the link still standing.
                        ready = pending is None
                        preview_absent = ready
                else:
                    report(
                        "container is a link",
                        rel_path,
                        f"points at {actual}, outside the repository, so it is "
                        "left alone; this has to be a real directory",
                        fix,
                        pending,
                    )
            elif absent:
                if report("container missing", rel_path, None, fix, pending):
                    try:
                        make_container(home_target, rel_path)
                    except OSError as e:
                        failed(f"Creating the directory failed: {e}")
                    else:
                        # Past this point the directory exists. Whatever else
                        # goes wrong is about the directory that is now there,
                        # never about creating it. Reporting a creation
                        # failure here left the children waiting on something
                        # already present on disk.
                        applied("Created as a directory.")
                        ready = True
                        try:
                            tighten_private(home_target, rel_path)
                        except OSError as e:
                            # Not a finding of its own: the entry is already
                            # counted as applied, and one entry occupies one
                            # bucket. Said plainly instead.
                            print(
                                paint(
                                    f"  Created, but its mode could not be "
                                    f"narrowed to 0700: {e}",
                                    "1;31",
                                )
                            )
                else:
                    # Nothing was created, but --fix would have. Only a pending
                    # ancestor keeps that from being true.
                    ready = pending is None
            elif home_target.is_dir():
                # Already a real directory, so its children can go in. The mode
                # is a separate question: make_container only ever sets one at
                # creation, and tightening it here would modify something that
                # was in place before this script ran.
                mode = home_target.stat().st_mode & 0o777
                if str(rel_path) in PRIVATE_CONTAINERS and mode & 0o077:
                    report(
                        "container is not private",
                        rel_path,
                        f"mode {mode:04o}, which other accounts can read; "
                        "chmod it to 0700 yourself",
                        fix,
                        pending,
                    )
                else:
                    verified(
                        "container verified",
                        rel_path,
                        f"real directory, mode {mode:04o}",
                    )
                ready = True
            elif home_target.is_file():
                report(
                    "container is a file",
                    rel_path,
                    "has to be a real directory so it can hold both "
                    "repository links and your own files; move the file aside",
                    fix,
                    pending,
                )
            else:
                # A socket, a fifo, a device node. Leaving it unmentioned hid
                # the whole subtree behind it.
                report(
                    "container is not a directory",
                    rel_path,
                    "something that is neither a file nor a directory is here; "
                    "move it aside",
                    fix,
                    pending,
                )

            # Descend either way, so the listing covers the children of a
            # container that is not there yet; act on them only once it is.
            audit_and_fix(
                item,
                fix,
                None if ready else (pending or str(rel_path)),
                as_absent or preview_absent,
            )
            continue

        # Default: link the entry whole, file or directory alike.
        if absent:
            if report("link missing", rel_path, None, fix, pending):
                try:
                    link(home_target, item)
                    applied("Linked.")
                except OSError as e:
                    failed(f"Linking failed: {e}")
            continue

        if is_link:
            actual = os.readlink(home_target)
            target = Path(actual)
            if not target.is_absolute():
                target = Path(os.path.normpath(home_target.parent / target))

            # Checked before the equality test below, so a link routed through
            # an old layout is still named as such even when it happens to
            # come out at the right place.
            # A pattern that occurs in this entry's own correct target cannot
            # tell a leftover link from the right one. Ignoring it there costs
            # only the label: a link pointing somewhere else is still reported,
            # as a wrong target. Left in, it would name the link this script
            # had just created correctly, and --fix would relink it to the same
            # place and report it again on the next run, for ever.
            stale = any(
                p in actual or p in str(target)
                for p in BAD_LINK_PATTERNS
                if p not in str(item)
            )
            if target == item and not stale:
                verified("link verified", rel_path, f"symlink -> {item}")
                continue

            tag = "stale link" if stale else "wrong target"
            if inside_repo(target):
                # Names the wrong thing, but names it inside the repository,
                # so the link is all there is to lose. The commonest case is a
                # layout this script itself used to produce.
                if report(
                    tag,
                    rel_path,
                    f"points at {actual}, inside the repository, so the link "
                    "is all there is to lose; --fix relinks it",
                    fix,
                    pending,
                    klass=CREATE,
                ):
                    try:
                        remove_repo_link(home_target)
                        link(home_target, item)
                    except OSError as e:
                        failed(f"Relinking failed: {e}")
                    else:
                        applied("Relinked.")
            else:
                report(
                    tag,
                    rel_path,
                    f"points at {actual}, outside the repository, so it is "
                    "left alone; remove the link and run again",
                    fix,
                    pending,
                )
            continue

        # Real content of some kind is already there. A directory may hold
        # entries the repository does not, and a file may be the only copy of
        # something; either way only you know what it is worth. For a directory
        # there is a second answer worth naming, since listing it in CONTAINERS
        # keeps both sides instead of choosing between them.
        detail = (
            "a directory of yours; this wanted to link the repository's copy "
            "here. Move it aside, or edit link.py to link its contents one by "
            "one and keep both"
            if home_target.is_dir()
            else "already here; this wanted to link the repository's copy here. "
            "Move it aside and run again"
        )
        report("in the way", rel_path, detail, fix, pending)


def scan_dirs():
    """Where the reverse scan looks: $HOME, and one level inside each container.

    One level, because that is exactly as deep as the forward walk goes. A
    container holds repo-managed entries beside local ones; below that the
    repository never had anything, so nothing there can be its leftover.
    """
    yield HOME
    for name in sorted(CONTAINERS):
        directory = HOME / name
        if directory.is_dir() and not directory.is_symlink():
            yield directory


def scan_orphans(fix):
    """Report $HOME links into the repository whose target it no longer has.

    The forward walk enumerates the repository, so the one thing it structurally
    cannot see is a path the repository stopped having. Those links stay in
    $HOME for ever, pointing at nothing, while a run reports everything
    verified. On one server there were nine.

    Removing one is the same trade as clearing any other link into the
    repository: it holds no content, and here it does not even hold a
    direction worth keeping. A dangling link pointing anywhere else is not
    this script's to judge and is passed over in silence.
    """
    printed = False

    def header():
        nonlocal printed
        if not printed:
            print(paint("Links into the repository:", "2"))
            printed = True

    for directory in scan_dirs():
        try:
            entries = sorted(directory.iterdir())
        except OSError as e:
            print(paint(f"  Could not read {directory}: {e}", "1;31"))
            scan_counts["failed"] += 1
            continue

        # Whether this run leaves the directory holding nothing. Every entry
        # has to be a leftover this run clears; anything else (a file of
        # yours, a link pointing elsewhere, a removal that failed) keeps it
        # alive. An audit answers by prediction rather than observation, since
        # the links it only lists are the ones a --fix run takes away; both
        # modes therefore reach the same verdict from the same starting state.
        # Vacuously true for a directory already emptied by an earlier run,
        # which is what makes the finding survive a second --fix.
        emptied = True

        for path in entries:
            if path in visited or not path.is_symlink():
                emptied = False
                continue
            try:
                actual, target = link_target(path)
            except OSError:
                emptied = False
                continue
            if not inside_repo(target):
                emptied = False
                continue

            rel_path = path.relative_to(HOME)
            if target.exists():
                # A link into the repository the walk never reached: it names
                # something real, so nothing is wrong with it, but saying so
                # is how --verbose shows what the scan covered.
                emptied = False
                scan_counts["verified"] += 1
                if VERBOSE:
                    header()
                    print(
                        row(
                            "link verified",
                            "34",
                            home_display(rel_path),
                            paint(f"symlink -> {actual}", "2"),
                        )
                    )
                continue

            header()

            acting = fix
            parts = [f"(points at {actual}, which the repository no longer has)"]
            if not acting:
                parts.append(paint("Needs --fix.", "2"))
                scan_counts["to_remove"] += 1
            print(row("orphaned link", "32", home_display(rel_path), "  ".join(parts)))
            if not acting:
                continue
            try:
                remove_repo_link(path)
            except OSError as e:
                scan_counts["failed"] += 1
                emptied = False
                print(paint(f"  Removing the link failed: {e}", "1;31"))
            else:
                scan_counts["removed"] += 1
                print(paint("  Removed.", "2"))

        # A container this run leaves behind with nothing in it. Two conditions,
        # both decidable: the repository has no entry at this path, and every
        # entry the directory holds is a leftover this run clears. Together they
        # leave one reading: what it held were links into a repository that has
        # nothing there any more, so the directory is the residue of that. A
        # container whose repository entry still exists is passed over: empty is
        # a legitimate state for one whose contents have not been created yet.
        #
        # MANUAL, and reported rather than removed. A symlink carries no content
        # of its own, which is what makes clearing one safe; a directory is not
        # the same trade even when empty, since its being there may be an
        # arrangement of yours that predates this script.
        if directory == HOME or not emptied:
            continue
        rel_path = directory.relative_to(HOME)
        # lexists, not exists: a repository entry that is itself a dangling
        # symlink is still an entry, and the forward walk has already named it.
        if os.path.lexists(SRC / rel_path):
            continue
        header()
        scan_counts["left_empty"] += 1
        print(
            row(
                "container left empty",
                "31",
                home_display(rel_path),
                "(the repository no longer has this path, and nothing is left in "
                "the directory; remove it yourself if you want it gone)",
            )
        )


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Keep the dotfile symlinks in $HOME pointing at this repository."
    )
    parser.add_argument(
        "--fix",
        action="store_true",
        help="create what is missing; leave anything already in place alone",
    )
    parser.add_argument(
        "--verbose",
        action="store_true",
        help="also list the entries that are already correct, and the excluded ones",
    )
    args = parser.parse_args()
    VERBOSE = args.verbose

    if SRC == HOME:
        sys.exit(
            f"{SRC} is $HOME itself, so every entry would be its own target. "
            "Keep the repository in a directory of its own."
        )

    print(
        "Creating what is missing. Anything already there is left alone."
        if args.fix
        else "Audit only. Pass --fix to create what is missing."
    )
    print(f"Source: {SRC}")
    print("-" * 60)

    try:
        audit_and_fix(SRC, fix=args.fix)
        # After the walk, so `visited` is complete and the scan can leave every
        # path the walk already spoke about alone.
        scan_orphans(fix=args.fix)
    except KeyboardInterrupt:
        where = f" while handling {current['entry']}" if current["entry"] else ""
        print(paint(f"\nInterrupted{where}.", "1;31"))
        sys.exit(1)

    print("-" * 60)

    # An accounting, not a sentence: this is a check over a fixed set of
    # entries, so every one of them is placed and the parts add up to the total.
    # Excluded entries are reported apart from it, never folded in, because
    # they were never examined.
    head = "Fix" if args.fix else "Audit"
    examined = counts["examined"]

    # A sentence of its own in either form, never a row among the buckets:
    # these entries were not examined, so adding them to the rows made the rows
    # come to more than the total printed above them.
    excluded_note = f" {counts['excluded']} excluded." if counts["excluded"] else ""

    if examined == 0:
        print(f"{head}: nothing to examine." + paint(excluded_note, "2"))
    elif counts["verified"] == examined:
        # Only the verdict is coloured, in the same blue as the verified row
        # below: the framing reads the same here as in the itemised form,
        # where the header carries no colour either.
        print(
            f"{head}: {examined} entries examined, "
            + paint("all verified", "34")
            + "."
            + paint(excluded_note, "2")
        )
    else:
        print(f"{head}: {examined} entries examined." + paint(excluded_note, "2"))
        # (count, label, colour). The colour of a row is the colour its
        # findings carried in the listing, so nothing changes meaning between
        # the two: green is what --fix carries out, yellow is waiting on a
        # container, red is yours to clear in $HOME, magenta is the
        # repository's to fix, blue is already checked.
        rows = [
            ("applied", "created", "32"),
            ("verified", "verified", "34"),
            ("to_create", "to create", "32"),
            ("skipped", "for you to clear", "31"),
            ("blocked", None, "33"),
            ("repo", "to fix in the repository", "35"),
            ("failed", "failed", "1;31"),
        ]
        for key, label, code in rows:
            n = counts[key]
            if not n:
                continue
            if key == "blocked":
                sole = next(iter(blockers)) if len(blockers) == 1 else None
                label = f"waiting on {sole}" if sole else "waiting on a container"
            print(paint(f"  {n:>3} {label}", code))

        # The rows are a partition of the total, so they have to come to it. If
        # they ever do not, saying so is the only honest thing left: a check
        # that cannot account for its own findings must not print a total as
        # though it could.
        placed = sum(counts[k] for k in BUCKETS)
        if placed != examined:
            print(
                paint(
                    f"  Accounting is off: {placed} placed against "
                    f"{examined} examined. This is a defect in link.py.",
                    "1;31",
                )
            )

    # The reverse scan's own line, kept out of the accounting above: its
    # entries are not in the repository, so they were never among the examined
    # ones and adding them would make the parts add up to a different total.
    scan_parts = []
    if scan_counts["removed"]:
        scan_parts.append(paint(f"{scan_counts['removed']} orphaned removed", "32"))
    if scan_counts["to_remove"]:
        scan_parts.append(paint(f"{scan_counts['to_remove']} orphaned to remove", "32"))
    if scan_counts["left_empty"]:
        n = scan_counts["left_empty"]
        scan_parts.append(
            paint(f"{n} director{'y' if n == 1 else 'ies'} left empty", "31")
        )
    if scan_counts["failed"]:
        scan_parts.append(paint(f"{scan_counts['failed']} failed", "1;31"))
    if VERBOSE and scan_counts["verified"]:
        scan_parts.append(paint(f"{scan_counts['verified']} sound", "34"))
    if scan_parts:
        print("Links into the repository: " + ", ".join(scan_parts) + ".")

    # Non-zero whenever anything is left outstanding, so a provisioning script
    # notices a run that reported politely and changed nothing.
    sys.exit(
        1
        if counts["to_create"]
        or counts["skipped"]
        or counts["blocked"]
        or counts["repo"]
        or counts["failed"]
        or scan_counts["to_remove"]
        or scan_counts["left_empty"]
        or scan_counts["failed"]
        else 0
    )
