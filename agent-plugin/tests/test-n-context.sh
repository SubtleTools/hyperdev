#!/usr/bin/env bash
# Row N — the SessionStart context hook (hyper-context.sh). The hook's whole
# job is telling a session where it is, so each position must name the layout
# and the rule that position gets wrong. Multi-repo has four of them; the
# single-repo output must not have drifted.
#
# The hook is run the way the harness runs it — piping hook JSON into the
# script — never by sourcing it, so PWD is the only position signal.

source "$(dirname "${BASH_SOURCE[0]}")/helpers.sh"
set +eu
set +o pipefail

CTX="$SCRIPTS_DIR/hyper-context.sh"

# run_ctx <dir> — the hook's stdout when a session starts in <dir>
run_ctx() {
  (cd "$1" 2>/dev/null && echo '{"hook_event_name":"SessionStart"}' | bash "$CTX" 2>/dev/null)
}

# N1: multi-repo, at the space root
d="$FIX/n1"; make_multi_space "$d" alpha beta
out="$(run_ctx "$d")"
assert_contains "root: names the multi-repo layout" "$out" "multi-repo space"
assert_contains "root: says cwd is the space ROOT" "$out" "space ROOT"
assert_contains "root: says the root is not a git repository" "$out" "not a git repository"
assert_contains "root: lists slug alpha" "$out" "alpha"
assert_contains "root: lists slug beta" "$out" "beta"
assert_contains "root: wt switch runs inside code/<slug>/" "$out" "code/<slug>/"

# N2: multi-repo, in a local-only directory
mkdir -p "$d/notes/deep"
out="$(run_ctx "$d/notes/deep")"
assert_contains "local-only: names the directory" "$out" "notes/deep/"
assert_contains "local-only: says it is a local-only directory" "$out" "local-only directory"
assert_contains "local-only: names the multi-repo layout" "$out" "multi-repo space"
assert_contains "local-only: lists the repos" "$out" "alpha"
assert_contains "local-only: wt switch runs inside code/<slug>/" "$out" "code/<slug>/"

# N3: multi-repo, inside code/<slug>/ but not in a worktree
out="$(run_ctx "$d/code/alpha")"
assert_contains "repo root: names the repo" "$out" 'Repo `alpha`'
assert_contains "repo root: names the multi-repo space" "$out" "multi-repo space"
assert_contains "repo root: warns off committing here" "$out" "Do not run git commit"
assert_contains "repo root: points at this repo's worktrees" "$out" "code/alpha/worktrees"
assert_contains "repo root: lists the repos" "$out" "beta"

# N4: multi-repo, inside a worktree of one slug — at the top and deeper
out="$(run_ctx "$d/code/beta/worktrees/main")"
assert_contains "worktree: names the worktree" "$out" 'Worktree `main`'
assert_contains "worktree: names the owning slug" "$out" 'repo `beta`'
assert_contains "worktree: names the multi-repo space" "$out" "multi-repo space"
assert_contains "worktree: says normal git applies" "$out" "Normal git applies"
assert_contains "worktree: lists the repos" "$out" "alpha"
assert_contains "worktree: wt switch runs inside code/<slug>/" "$out" "code/<slug>/"

mkdir -p "$d/code/beta/worktrees/main/src/deep"
out="$(run_ctx "$d/code/beta/worktrees/main/src/deep")"
assert_contains "deep in worktree: still names the worktree" "$out" 'Worktree `main`'
assert_contains "deep in worktree: still names the slug" "$out" 'repo `beta`'

# N5: single-repo regression — the bare output must be unchanged, and must
# never acquire multi-repo wording.
d2="$FIX/n5"; make_bare_space "$d2"
touch "$d2/HYPER.md"
out="$(run_ctx "$d2")"
assert_contains "bare root: still says cwd is the space ROOT" "$out" "space ROOT"
assert_contains "bare root: still says the .git here is bare" "$out" "The .git here is bare"
assert_contains "bare root: still points at worktrees/<branch>" "$out" "worktrees/<branch>"
assert_not_contains "bare root: no multi-repo wording" "$out" "multi-repo"
assert_not_contains "bare root: no code/ path" "$out" "code/<slug>"

git --git-dir="$d2/.git" worktree add -q "$d2/worktrees/feat" -b feat 2>/dev/null
out="$(run_ctx "$d2/worktrees/feat")"
assert_contains "bare worktree: names the worktree" "$out" 'Worktree `feat`'
assert_not_contains "bare worktree: no multi-repo wording" "$out" "multi-repo"

mkdir -p "$d2/notes"
out="$(run_ctx "$d2/notes")"
assert_contains "bare local-only: names the directory" "$out" "notes/"
assert_contains "bare local-only: says local-only" "$out" "local-only directory"
assert_not_contains "bare local-only: no multi-repo wording" "$out" "multi-repo"

# N6: outside any space the hook stays silent — it must cost nothing in an
# unrelated project.
d3="$FIX/n6"; make_checkout "$d3"
out="$(run_ctx "$d3")"
assert_eq "plain checkout produces no context" "" "$out"

finish
