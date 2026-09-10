#!/usr/bin/env bash
# Row A — layout detection (hyper-lib.sh: space_layout / is_space /
# find_space_root). The opt-in gate is the safety property under test:
# nothing counts as a space unless the structure or the marker says so.

source "$(dirname "${BASH_SOURCE[0]}")/helpers.sh"
# hyper-lib.sh turns on strict mode when sourced; the harness must not
# abort on the first failing assertion, so switch it back off.
source "$SCRIPTS_DIR/hyper-lib.sh"
set +eu
set +o pipefail

# A1: bare .git + worktrees/ — self-identifying
d="$FIX/a1"; make_bare_space "$d"
assert_eq "bare + worktrees/ -> bare" "bare" "$(space_layout "$d")"
assert_ok "bare + worktrees/ is a space" is_space "$d"

# A2: bare .git + HYPER.md marker, no worktrees/
d="$FIX/a2"; mkdir -p "$d"; git init -q --bare "$d/.git"
touch "$d/HYPER.md"
assert_eq "bare + marker -> bare" "bare" "$(space_layout "$d")"

# A3: plain bare repo (a mirror / hosting remote) — no worktrees, no marker
d="$FIX/a3"; mkdir -p "$d"; git init -q --bare "$d/.git"
assert_fails "plain bare repo rejected by space_layout" space_layout "$d"
assert_fails "plain bare repo is not a space" is_space "$d"

# A4: checkout + marker. The checkout layout no longer exists, and is_space
# has no marker-only fallback: HYPER.md lives at the uncommittable bare
# root, so a marker inside an ordinary checkout is legacy debris (or a
# committed copy in a clone) and must not give that checkout space semantics.
d="$FIX/a4"; make_checkout "$d"
touch "$d/HYPER.md"
assert_eq "checkout + marker -> no layout" "" "$(space_layout "$d")"
assert_fails "checkout + marker rejected by space_layout" space_layout "$d"
assert_fails "checkout + marker rejected by is_space (no marker fallback)" is_space "$d"

# A5: checkout with .claude/worktrees/ only — the old structural opt-in is
# gone. Without the marker this is just a plain checkout, not a space.
d="$FIX/a5"; make_checkout "$d"
mkdir -p "$d/.claude/worktrees"
assert_fails ".claude/worktrees/ alone no longer opts a checkout in" space_layout "$d"
assert_fails "checkout with only .claude/worktrees/ is not a space" is_space "$d"

# A6: ordinary repo, no marker, no .claude/worktrees — must NOT be a space
d="$FIX/a6"; make_checkout "$d"
assert_fails "plain checkout rejected by space_layout" space_layout "$d"
assert_fails "plain checkout is not a space" is_space "$d"

# A7: linked worktree (.git is a file) inside a bare space. The worktree
# itself must be rejected — even if a HYPER.md is present inside it — and
# find_space_root must walk past it to the bare root.
d="$FIX/a7"; make_bare_space "$d"
git --git-dir="$d/.git" worktree add -q "$d/worktrees/feat" -b feat 2>/dev/null \
  || git --git-dir="$d/.git" worktree add -q "$d/worktrees/feat" feat
wt="$d/worktrees/feat"
touch "$wt/HYPER.md"
assert_fails "linked worktree rejected by space_layout" space_layout "$wt"
assert_fails "linked worktree is not a space" is_space "$wt"
mkdir -p "$wt/sub"
assert_eq "find_space_root from inside the worktree reaches the bare root" \
  "$d" "$(find_space_root "$wt/sub")"

# A8: subdirectory of a marked checkout — the marker gives it nothing now, so
# the upward walk finds no space at all.
d="$FIX/a8"; make_checkout "$d"
touch "$d/HYPER.md"
mkdir -p "$d/src"
assert_fails "subdirectory of a checkout rejected" space_layout "$d/src"
assert_fails "find_space_root finds nothing above a marked checkout" \
  find_space_root "$d/src"

# --- multi-repo layout -----------------------------------------------------

# A9: the shape itself — marker, no .git at the root, bare repos under code/
d="$FIX/a9"; make_multi_space "$d" alpha beta
assert_eq "marker + code/*/.git bare -> multi" "multi" "$(space_layout "$d")"
assert_ok "a multi-repo space is a space" is_space "$d"
assert_eq "space_repos lists every slug" "alpha
beta" "$(space_repos "$d")"
assert_eq "space_repos prints nothing for a bare space" "" "$(space_repos "$FIX/a1")"

# A10: find_space_root reaches the root from every position. The repo dir is
# the interesting one: it is a bare repo with worktrees/ beside it, so on its
# own it looks exactly like a bare space and the walk must not stop there.
mkdir -p "$d/notes/deep" "$d/code/beta/worktrees/main/src/deep"
assert_eq "find_space_root from the root" "$d" "$(find_space_root "$d")"
assert_eq "find_space_root from a local-only dir" "$d" "$(find_space_root "$d/notes")"
assert_eq "find_space_root from deep in a local-only dir" "$d" "$(find_space_root "$d/notes/deep")"
assert_eq "find_space_root from code/<slug>/" "$d" "$(find_space_root "$d/code/alpha")"
assert_eq "find_space_root from a worktree" "$d" "$(find_space_root "$d/code/beta/worktrees/main")"
assert_eq "find_space_root from deep inside a worktree" \
  "$d" "$(find_space_root "$d/code/beta/worktrees/main/src/deep")"

# A11: the derived helpers
assert_eq "repo_slug_of names the owning slug" "beta" \
  "$(repo_slug_of "$d" "$d/code/beta/worktrees/main/src/deep")"
assert_eq "repo_slug_of at the repo dir itself" "alpha" "$(repo_slug_of "$d" "$d/code/alpha")"
assert_fails "repo_slug_of has no answer at the space root" repo_slug_of "$d" "$d"
assert_fails "repo_slug_of has no answer in a local-only dir" repo_slug_of "$d" "$d/notes"
assert_eq "worktrees_dir is per-repo in a multi space" \
  "$d/code/alpha/worktrees" "$(worktrees_dir "$d" alpha)"
assert_fails "worktrees_dir needs a slug in a multi space" worktrees_dir "$d"
assert_eq "worktrees_dir is the root's in a bare space" \
  "$FIX/a1/worktrees" "$(worktrees_dir "$FIX/a1")"

# A12: at_space_root distinguishes the root from everything below it
( cd "$d" && at_space_root ) && pass "at_space_root true at a multi-repo root" \
  || fail "at_space_root true at a multi-repo root"
( cd "$d/code/alpha" && at_space_root ) && fail "at_space_root false in a repo dir" \
  || pass "at_space_root false in a repo dir"
( cd "$d/notes" && at_space_root ) && fail "at_space_root false in a local-only dir" \
  || pass "at_space_root false in a local-only dir"

# A13: negative — a root with its own .git is the bare shape, never multi,
# whatever else sits under code/.
d="$FIX/a13"; mkdir -p "$d/code/x"
git init -q --bare "$d/.git"
git init -q --bare "$d/code/x/.git"
touch "$d/HYPER.md"
assert_eq "root with .git AND code/ is bare, not multi" "bare" "$(space_layout "$d")"

# A14: negative — a non-bare repo under code/ does not count, so a directory
# of ordinary checkouts is not a space.
d="$FIX/a14"; mkdir -p "$d"
touch "$d/HYPER.md"
make_checkout "$d/code/y"
assert_eq "code/<slug>/.git non-bare -> no layout" "" "$(space_layout "$d")"
assert_fails "a directory of plain checkouts is not a space" is_space "$d"

# A15: negative — bare repos under code/ but no marker. Nothing self-identifies
# here the way a bare root does, so the marker is mandatory.
d="$FIX/a15"; mkdir -p "$d/code/z"
git init -q --bare "$d/code/z/.git"
assert_eq "bare repos under code/ without a marker -> no layout" "" "$(space_layout "$d")"

# A16: the legacy marker opts a multi-repo space in too
d="$FIX/a16"; make_multi_space "$d" solo
mv "$d/HYPER.md" "$d/HYPERDEV.md"
assert_eq "legacy HYPERDEV.md marker still detects multi" "multi" "$(space_layout "$d")"

# A17: write_hyper_md documents the layout the root actually has — a
# multi-repo space must never be handed the bare template telling it to look
# for a .git and a worktrees/ it does not have.
d="$FIX/a17"; make_multi_space "$d" alpha beta
write_hyper_md "$d" a17
md="$(cat "$d/HYPER.md")"
assert_contains "multi HYPER.md names the multi-repo layout" "$md" "multi-repo layout"
assert_contains "multi HYPER.md says the root is not a git repository" "$md" "not a git
repository"
assert_contains "multi HYPER.md documents the per-repo .git" "$md" '`code/<repo-slug>/.git`'
assert_contains "multi HYPER.md documents the per-repo worktrees" "$md" '`code/<repo-slug>/worktrees/<branch>`'
assert_contains "multi HYPER.md has a Repositories table" "$md" "## Repositories"
assert_contains "multi HYPER.md rows every slug (alpha)" "$md" '| `alpha` |'
assert_contains "multi HYPER.md rows every slug (beta)" "$md" '| `beta` |'
assert_contains "multi HYPER.md records the default branch" "$md" '`main` |'
assert_contains "multi HYPER.md says wt switch runs inside code/<slug>/" "$md" 'inside `code/<slug>/`'
assert_not_contains "multi HYPER.md never claims a bare root .git" "$md" '| `.git/` |'

# The bare template is untouched by the dispatch.
d="$FIX/a17b"; make_bare_space "$d"
write_hyper_md "$d" a17b
md="$(cat "$d/HYPER.md")"
assert_contains "bare HYPER.md still says bare layout" "$md" "bare layout"
assert_contains "bare HYPER.md still documents the root .git" "$md" '| `.git/` |'
assert_not_contains "bare HYPER.md has no Repositories table" "$md" "## Repositories"
assert_not_contains "bare HYPER.md never mentions code/<repo-slug>" "$md" "code/<repo-slug>"

# scaffold_dirs must not invent a root worktrees/ in a multi-repo space.
d="$FIX/a17c"; make_multi_space "$d" solo
scaffold_dirs "$d" >/dev/null 2>&1
assert_ok "scaffold_dirs creates the local-only dirs" test -d "$d/notes"
assert_ok "scaffold_dirs creates no worktrees/ at a multi root" test ! -d "$d/worktrees"
d="$FIX/a17d"; make_bare_space "$d"
scaffold_dirs "$d" >/dev/null 2>&1
assert_ok "scaffold_dirs still creates worktrees/ in a bare space" test -d "$d/worktrees"

finish
