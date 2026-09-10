#!/usr/bin/env bash
# Row G — the read-only audit (hyper-audit.sh): a healthy space reports no
# problems, an orphaned worktree is classified ORPHANED, and secret-looking
# files are reported by path only — contents must never leak into the report.

source "$(dirname "${BASH_SOURCE[0]}")/helpers.sh"
set +eu
set +o pipefail

AUDIT="$SCRIPTS_DIR/hyper-audit.sh"

# G1: fully healthy bare space
d="$FIX/g1"; make_bare_space "$d"
mkdir -p "$d/data" "$d/notes" "$d/scratch" "$d/bin"
touch "$d/HYPER.md"
out="$(bash "$AUDIT" "$d" 2>&1)"
rc=$?
assert_eq "healthy space -> exit 0" 0 "$rc"
probs="$(printf '%s\n' "$out" | awk '/^Problems:/{f=1;next} /^Warnings:/{f=0} f')"
warns="$(printf '%s\n' "$out" | awk '/^Warnings:/{f=1;next} /^Info:/{f=0} f')"
assert_contains "healthy space reports no problems" "$probs" "(none)"
assert_contains "healthy space reports no warnings" "$warns" "(none)"

# G2: orphaned worktree — .git file whose gitdir no longer exists
d="$FIX/g2"; make_bare_space "$d"
mkdir -p "$d/data" "$d/notes" "$d/scratch" "$d/bin"
touch "$d/HYPER.md"
mkdir -p "$d/worktrees/dead"
printf 'gitdir: %s\n' "$FIX/nonexistent/gitdirs/dead" > "$d/worktrees/dead/.git"
out="$(bash "$AUDIT" "$d" 2>&1)"
probs="$(printf '%s\n' "$out" | awk '/^Problems:/{f=1;next} /^Warnings:/{f=0} f')"
assert_contains "dangling gitdir classified as ORPHANED" "$probs" "ORPHANED"
assert_contains "the orphan is named" "$probs" "worktrees/dead"

# G3: .env at the root — path printed, contents never
d="$FIX/g3"; make_bare_space "$d"
mkdir -p "$d/data" "$d/notes" "$d/scratch" "$d/bin"
touch "$d/HYPER.md"
echo 'API_KEY=HYPER_TEST_SECRET_VALUE_XYZZY' > "$d/.env"
out="$(bash "$AUDIT" "$d" 2>&1)"
assert_contains "the .env path is reported" "$out" ".env"
assert_not_contains "the .env contents never appear" "$out" "HYPER_TEST_SECRET_VALUE_XYZZY"

# --- multi-repo spaces -----------------------------------------------------

# G4: a healthy multi-repo space. The absent worktrees/ at the root is the
# correct shape here, so it must never be reported as drift.
d="$FIX/g4"; make_multi_space "$d" alpha beta
mkdir -p "$d/data" "$d/notes" "$d/scratch" "$d/bin"
out="$(bash "$AUDIT" "$d" 2>&1)"
rc=$?
assert_eq "healthy multi space -> exit 0" 0 "$rc"
assert_contains "layout reported as multi" "$out" "Layout: multi"
assert_contains "the repos are listed" "$out" "alpha, beta"
probs="$(printf '%s\n' "$out" | awk '/^Problems:/{f=1;next} /^Warnings:/{f=0} f')"
warns="$(printf '%s\n' "$out" | awk '/^Warnings:/{f=1;next} /^Info:/{f=0} f')"
assert_contains "healthy multi space reports no problems" "$probs" "(none)"
assert_contains "healthy multi space reports no warnings" "$warns" "(none)"
assert_not_contains "the absent root worktrees/ is not drift" "$out" "missing worktrees/"

# Each repo's live worktree is reported, labelled with its slug.
infos="$(printf '%s\n' "$out" | awk '/^Info:/{f=1} f')"
assert_contains "alpha's worktree is labelled with its slug" "$infos" "code/alpha/worktrees/main"
assert_contains "beta's worktree is labelled with its slug" "$infos" "code/beta/worktrees/main"

# G5: debris in one repo is found, named with that repo's slug, and the other
# repo stays clean.
d="$FIX/g5"; make_multi_space "$d" alpha beta
mkdir -p "$d/data" "$d/notes" "$d/scratch" "$d/bin"
mkdir -p "$d/code/beta/worktrees/dead"
printf 'gitdir: %s\n' "$FIX/nonexistent/gitdirs/dead" > "$d/code/beta/worktrees/dead/.git"
mkdir -p "$d/code/alpha/worktrees/buildout"
echo artifact > "$d/code/alpha/worktrees/buildout/out.bin"
out="$(bash "$AUDIT" "$d" 2>&1)"
probs="$(printf '%s\n' "$out" | awk '/^Problems:/{f=1;next} /^Warnings:/{f=0} f')"
warns="$(printf '%s\n' "$out" | awk '/^Warnings:/{f=1;next} /^Info:/{f=0} f')"
assert_contains "orphan in beta classified ORPHANED" "$probs" "ORPHANED"
assert_contains "the orphan is named with its slug" "$probs" "code/beta/worktrees/dead"
assert_contains "leftover in alpha named with its slug" "$warns" "code/alpha/worktrees/buildout"

# G6: a gone branch is labelled with the repo that owns it. No network: push
# to a local bare "remote" with -u, delete it there, fetch -p.
d="$FIX/g6"; make_multi_space "$d" alpha beta
mkdir -p "$d/data" "$d/notes" "$d/scratch" "$d/bin"
git init -q --bare "$FIX/g6-remote.git"
git --git-dir="$d/code/beta/.git" remote add origin "$FIX/g6-remote.git"
git --git-dir="$d/code/beta/.git" branch gone-in-beta main
git --git-dir="$d/code/beta/.git" push -q -u origin gone-in-beta 2>/dev/null
git --git-dir="$d/code/beta/.git" push -q origin --delete gone-in-beta 2>/dev/null
git --git-dir="$d/code/beta/.git" fetch -qp origin 2>/dev/null
out="$(bash "$AUDIT" "$d" 2>&1)"
warns="$(printf '%s\n' "$out" | awk '/^Warnings:/{f=1;next} /^Info:/{f=0} f')"
assert_contains "gone branch is labelled with its repo" "$warns" "beta/gone-in-beta"

finish
