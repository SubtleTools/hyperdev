#!/usr/bin/env bash
# Row K — cleanup (hyper-cleanup.sh), the one script that deletes. List
# mode must enumerate every debris class and touch nothing; --delete must
# re-verify each id at deletion time, refuse anything live or unknown, and
# never escalate (-d only for branches, contents-only for scratch/).

source "$(dirname "${BASH_SOURCE[0]}")/helpers.sh"
set +eu
set +o pipefail

CLEANUP="$SCRIPTS_DIR/hyper-cleanup.sh"

# One rich fixture space shared by all rows: a bare space with a live
# worktree plus every debris class audit knows how to classify.
d="$FIX/k"
mkdir -p "$d"
git init -q --bare "$d/.git"
mkdir -p "$d/worktrees" "$d/data" "$d/notes" "$d/scratch" "$d/bin" "$d/.claude"
touch "$d/HYPER.md"

# Seed a commit on main and a live worktree checked out from it.
seed="$FIX/seed"
make_checkout "$seed"
git --git-dir="$d/.git" fetch -q "$seed" "refs/heads/main:refs/heads/main"
git --git-dir="$d/.git" symbolic-ref HEAD refs/heads/main
git --git-dir="$d/.git" worktree add -q "$d/worktrees/live" main 2>/dev/null

# Gone branches, no network: a local bare "remote" — push with -u, delete the
# remote branch, fetch -p, leaving %(upstream:track) = [gone].
git init -q --bare "$FIX/remote.git"
git --git-dir="$d/.git" remote add origin "$FIX/remote.git"
#   gone-merged: same tip as main, so `git branch -d` accepts it
git --git-dir="$d/.git" branch gone-merged main
#   gone-unmerged: one commit main does not have, so `git branch -d` refuses
git -C "$seed" checkout -qb extra
echo unique > "$seed/unique.txt"
git -C "$seed" add -A
git -C "$seed" commit -qm unique
git --git-dir="$d/.git" fetch -q "$seed" "refs/heads/extra:refs/heads/gone-unmerged"
for b in gone-merged gone-unmerged; do
  git --git-dir="$d/.git" push -q -u origin "$b" 2>/dev/null
  git --git-dir="$d/.git" push -q origin --delete "$b" 2>/dev/null
done
git --git-dir="$d/.git" fetch -qp origin 2>/dev/null

# Debris: orphan worktree (dangling gitdir), leftover build output (no .git),
# parked conversion entry, conversion evidence, memory backup, scratch junk.
mkdir -p "$d/worktrees/dead"
printf 'gitdir: %s\n' "$FIX/nowhere/gitdirs/dead" > "$d/worktrees/dead/.git"
echo stale > "$d/worktrees/dead/stale.txt"
mkdir -p "$d/worktrees/buildout"
echo artifact > "$d/worktrees/buildout/out.bin"
mkdir -p "$d/.claude/worktrees/oldwt"
echo parked > "$d/.claude/worktrees/oldwt/f.txt"
touch "$d/.hyper-convert.preflight"
touch "$d/.claude/MEMORY.md.hyper-orig"
echo junk1 > "$d/scratch/tmp1.txt"
mkdir -p "$d/scratch/sub"
echo junk2 > "$d/scratch/sub/tmp2.txt"

# K1: list mode — every debris id, never the live worktree, nothing deleted
before="$(find "$d" | sort)"
out="$(bash "$CLEANUP" "$d" 2>&1)"
rc=$?
assert_eq "list mode exits 0" 0 "$rc"
assert_contains "orphan listed"            "$out" "worktree:dead"
assert_contains "orphan evidence says ORPHANED" "$out" "ORPHANED"
assert_contains "leftover listed"          "$out" "worktree:buildout"
assert_contains "parked entry listed"      "$out" "parked:oldwt"
assert_contains "memory backup listed"     "$out" "backup:memory-index"
assert_contains "preflight listed"         "$out" "evidence:preflight"
assert_contains "gone merged branch listed"   "$out" "branch:gone-merged"
assert_contains "gone unmerged branch listed" "$out" "branch:gone-unmerged"
assert_contains "scratch contents listed"  "$out" "scratch:contents"
assert_not_contains "live worktree never a candidate" "$out" "worktree:live"
assert_contains "header says nothing was deleted" "$out" "nothing has been deleted"
after="$(find "$d" | sort)"
assert_eq "list mode deleted nothing (snapshot identical)" "$before" "$after"

# K2: --delete of the orphan id
out="$(bash "$CLEANUP" "$d" --delete worktree:dead 2>&1)"
rc=$?
assert_eq "orphan delete exits 0" 0 "$rc"
assert_contains "orphan reported deleted" "$out" "deleted worktree:dead"
assert_ok "orphan directory is gone" test ! -e "$d/worktrees/dead"
assert_ok "live worktree untouched" test -f "$d/worktrees/live/file.txt"
wtlist="$(git --git-dir="$d/.git" worktree list 2>&1)"
assert_not_contains "git worktree list no longer shows the orphan" "$wtlist" "worktrees/dead"
assert_contains "git worktree list still shows the live worktree" "$wtlist" "worktrees/live"

# K2b: --delete of the leftover (no .git) id
out="$(bash "$CLEANUP" "$d" --delete worktree:buildout 2>&1)"
rc=$?
assert_eq "leftover delete exits 0" 0 "$rc"
assert_contains "leftover reported deleted" "$out" "deleted worktree:buildout"
assert_ok "leftover directory is gone" test ! -e "$d/worktrees/buildout"

# K3: --delete of a live worktree's id is refused, exit 1, tree intact
out="$(bash "$CLEANUP" "$d" --delete worktree:live 2>&1)"
rc=$?
assert_eq "live worktree delete exits 1" 1 "$rc"
assert_contains "live worktree refused loudly" "$out" "refused worktree:live"
assert_contains "refusal names the reason" "$out" "LIVE"
assert_ok "live worktree intact after refusal" test -f "$d/worktrees/live/file.txt"

# K4: branch deletion — -d only
out="$(bash "$CLEANUP" "$d" --delete branch:gone-merged 2>&1)"
rc=$?
assert_eq "merged gone branch delete exits 0" 0 "$rc"
assert_contains "merged gone branch reported deleted" "$out" "deleted branch:gone-merged"
assert_fails "gone-merged branch is gone" \
  git --git-dir="$d/.git" show-ref --verify -q refs/heads/gone-merged

out="$(bash "$CLEANUP" "$d" --delete branch:gone-unmerged 2>&1)"
rc=$?
assert_eq "unmerged gone branch delete exits 1" 1 "$rc"
assert_contains "unmerged branch refused" "$out" "refused branch:gone-unmerged"
assert_contains "refusal points at manual -D" "$out" "git branch -D"
assert_ok "unmerged branch still exists" \
  git --git-dir="$d/.git" show-ref --verify -q refs/heads/gone-unmerged

# K5: scratch:contents empties scratch/ but keeps the directory
out="$(bash "$CLEANUP" "$d" --delete scratch:contents 2>&1)"
rc=$?
assert_eq "scratch delete exits 0" 0 "$rc"
assert_contains "scratch reported deleted with entry count" "$out" "deleted scratch:contents (2 entries"
assert_ok "scratch directory itself stays" test -d "$d/scratch"
left="$(find "$d/scratch" -mindepth 1 ! -name .what-goes-here | wc -l | tr -d ' ')"
assert_eq "scratch is empty afterwards" 0 "$left"

# K6: evidence + backup ids, one invocation
out="$(bash "$CLEANUP" "$d" --delete evidence:preflight --delete backup:memory-index 2>&1)"
rc=$?
assert_eq "evidence+backup delete exits 0" 0 "$rc"
assert_contains "preflight reported deleted" "$out" "deleted evidence:preflight"
assert_contains "backup reported deleted" "$out" "deleted backup:memory-index"
assert_ok "preflight file gone" test ! -e "$d/.hyper-convert.preflight"
assert_ok "memory backup gone" test ! -e "$d/.claude/MEMORY.md.hyper-orig"

# K7: mixed call — the parked entry deletes, an unknown id is refused,
# and the refusal makes the whole run exit 1
out="$(bash "$CLEANUP" "$d" --delete parked:oldwt --delete bogus:nope 2>&1)"
rc=$?
assert_eq "mixed run exits 1 when any id is refused" 1 "$rc"
assert_contains "parked entry deleted in mixed run" "$out" "deleted parked:oldwt"
assert_contains "unknown id refused" "$out" "refused bogus:nope"
assert_ok "parked entry gone" test ! -e "$d/.claude/worktrees/oldwt"

# K8: ids can never point outside their class directory
out="$(bash "$CLEANUP" "$d" --delete "worktree:../data" 2>&1)"
rc=$?
assert_eq "traversal id exits 1" 1 "$rc"
assert_contains "traversal id refused" "$out" "refused worktree:../data"
assert_ok "data/ untouched by traversal attempt" test -d "$d/data"

# K9: a re-run of list mode on the cleaned space finds nothing but the
# remaining unmerged branch (which cleanup correctly refused to force)
out="$(bash "$CLEANUP" "$d" 2>&1)"
rc=$?
assert_eq "post-clean list exits 0" 0 "$rc"
assert_not_contains "no worktree candidates remain" "$out" "worktree:"
assert_not_contains "no parked candidates remain"   "$out" "parked:"
assert_not_contains "no scratch candidate remains"  "$out" "scratch:"
assert_contains "the refused branch is still a candidate" "$out" "branch:gone-unmerged"

# Interactive mode: without a tty the prompts would EOF into silent No answers,
# so the script must refuse loudly instead — and prove it deleted nothing.
pre="$(find "$d" | sort)"
out="$(bash "$CLEANUP" "$d" -i </dev/null 2>&1)"
rc=$?
assert_eq "interactive without a tty exits 2" 2 "$rc"
assert_contains "no-tty refusal names the agent alternative" "$out" "--delete"
assert_eq "no-tty interactive deleted nothing" "$pre" "$(find "$d" | sort)"
out="$(bash "$CLEANUP" "$d" -i --delete backup:memory-index 2>&1)"
rc=$?
assert_eq "-i with --delete is refused" 1 "$rc"
assert_contains "mutual-exclusion message" "$out" "mutually exclusive"

# --- multi-repo spaces -----------------------------------------------------
# Ids gain a "<slug>/" prefix so one id can never be ambiguous across repos;
# the safety contract (re-verify, refuse live, -d only) is unchanged.

m="$FIX/km"; make_multi_space "$m" alpha beta
mkdir -p "$m/data" "$m/notes" "$m/scratch" "$m/bin"

# Debris in both repos: an orphan in beta, a leftover in alpha.
mkdir -p "$m/code/beta/worktrees/dead"
printf 'gitdir: %s\n' "$FIX/nowhere/gitdirs/dead" > "$m/code/beta/worktrees/dead/.git"
echo stale > "$m/code/beta/worktrees/dead/stale.txt"
mkdir -p "$m/code/alpha/worktrees/buildout"
echo artifact > "$m/code/alpha/worktrees/buildout/out.bin"

# A gone branch in beta only.
git init -q --bare "$FIX/km-remote.git"
git --git-dir="$m/code/beta/.git" remote add origin "$FIX/km-remote.git"
git --git-dir="$m/code/beta/.git" branch gone-in-beta main
git --git-dir="$m/code/beta/.git" push -q -u origin gone-in-beta 2>/dev/null
git --git-dir="$m/code/beta/.git" push -q origin --delete gone-in-beta 2>/dev/null
git --git-dir="$m/code/beta/.git" fetch -qp origin 2>/dev/null

# KM1: list mode — every id carries its slug, live worktrees are never listed
before="$(find "$m" | sort)"
out="$(bash "$CLEANUP" "$m" 2>&1)"
rc=$?
assert_eq "multi list mode exits 0" 0 "$rc"
assert_contains "orphan listed with its slug"   "$out" "worktree:beta/dead"
assert_contains "leftover listed with its slug" "$out" "worktree:alpha/buildout"
assert_contains "gone branch listed with its slug" "$out" "branch:beta/gone-in-beta"
assert_not_contains "alpha's live worktree is never a candidate" "$out" "worktree:alpha/main"
assert_not_contains "beta's live worktree is never a candidate"  "$out" "worktree:beta/main"
assert_eq "multi list mode deleted nothing" "$before" "$(find "$m" | sort)"

# KM2: deleting a slugged orphan touches only that repo
out="$(bash "$CLEANUP" "$m" --delete worktree:beta/dead 2>&1)"
rc=$?
assert_eq "slugged orphan delete exits 0" 0 "$rc"
assert_contains "slugged orphan reported deleted" "$out" "deleted worktree:beta/dead"
assert_ok "the orphan is gone" test ! -e "$m/code/beta/worktrees/dead"
assert_ok "beta's live worktree untouched" test -f "$m/code/beta/worktrees/main/file.txt"
assert_ok "alpha's leftover untouched" test -e "$m/code/alpha/worktrees/buildout"

out="$(bash "$CLEANUP" "$m" --delete worktree:alpha/buildout 2>&1)"
assert_contains "slugged leftover reported deleted" "$out" "deleted worktree:alpha/buildout"
assert_ok "the leftover is gone" test ! -e "$m/code/alpha/worktrees/buildout"

# KM3: a live worktree is still refused, by slugged id
out="$(bash "$CLEANUP" "$m" --delete worktree:alpha/main 2>&1)"
rc=$?
assert_eq "slugged live worktree delete exits 1" 1 "$rc"
assert_contains "slugged live worktree refused" "$out" "refused worktree:alpha/main"
assert_contains "slugged refusal names the reason" "$out" "LIVE"
assert_ok "alpha's live worktree intact" test -f "$m/code/alpha/worktrees/main/file.txt"

# KM4: an id naming a repo that does not exist is refused, not resolved
out="$(bash "$CLEANUP" "$m" --delete worktree:nosuch/thing 2>&1)"
rc=$?
assert_eq "unknown slug exits 1" 1 "$rc"
assert_contains "unknown slug refused" "$out" "no repo 'nosuch'"

# KM5: traversal is still impossible through the slug or the entry name
out="$(bash "$CLEANUP" "$m" --delete "worktree:alpha/../../data" 2>&1)"
rc=$?
assert_eq "multi traversal id exits 1" 1 "$rc"
assert_ok "data/ untouched by multi traversal attempt" test -d "$m/data"

# KM6: branch deletion is per-repo — the slug picks the repo
out="$(bash "$CLEANUP" "$m" --delete branch:beta/gone-in-beta 2>&1)"
rc=$?
assert_eq "slugged branch delete exits 0" 0 "$rc"
assert_contains "slugged branch reported deleted" "$out" "deleted branch:beta/gone-in-beta"
assert_fails "the branch is gone from beta" \
  git --git-dir="$m/code/beta/.git" show-ref --verify -q refs/heads/gone-in-beta
assert_ok "alpha's main is untouched" \
  git --git-dir="$m/code/alpha/.git" show-ref --verify -q refs/heads/main

# KM7: space-level ids (not per-repo) keep working unchanged
touch "$m/.hyper-convert.preflight"
echo junk > "$m/scratch/tmp.txt"
out="$(bash "$CLEANUP" "$m" --delete evidence:preflight --delete scratch:contents 2>&1)"
rc=$?
assert_eq "space-level ids delete exits 0" 0 "$rc"
assert_contains "preflight deleted in a multi space" "$out" "deleted evidence:preflight"
assert_contains "scratch emptied in a multi space" "$out" "deleted scratch:contents"
assert_ok "scratch directory itself stays" test -d "$m/scratch"

finish
