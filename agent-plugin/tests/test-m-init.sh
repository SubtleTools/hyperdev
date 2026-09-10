#!/usr/bin/env bash
# Row M — init. The --new path builds a space from nothing: empty bare repo,
# seeded initial commit, default-branch worktree, full scaffold. The clone
# path is exercised implicitly by the conversion suite's fixtures; this file
# pins the from-scratch path and its refusals.

source "$(dirname "${BASH_SOURCE[0]}")/helpers.sh"

INIT="$SCRIPTS_DIR/hyper-init.sh"

# wt (worktrunk) may be installed on the machine running the suite; its
# user-level config would decide worktree placement. Strip it from PATH so
# the deterministic git-worktree fallback runs. git and node must survive.
clean_path="$(dirname "$(command -v git)"):/usr/bin:/bin"
node_dir="$(command -v node >/dev/null 2>&1 && dirname "$(command -v node)" || true)"
[[ -n "$node_dir" ]] && clean_path="$clean_path:$node_dir"

# M1: --new builds a working space from nothing
out="$( (cd "$FIX" && PATH="$clean_path" bash "$INIT" --new proj) 2>&1 )"
rc=$?
d="$FIX/proj"
assert_eq "--new exits 0" 0 "$rc"
assert_eq "repo is bare" "true" "$(git --git-dir="$d/.git" config --get core.bare)"
assert_ok "initial commit exists" git --git-dir="$d/.git" rev-parse refs/heads/main
assert_ok "worktree created for main" test -d "$d/worktrees/main"
assert_ok "worktree is functional" git -C "$d/worktrees/main" rev-parse HEAD
assert_eq "worktree is clean" "" "$(git -C "$d/worktrees/main" status --porcelain=v1)"
assert_eq "worktree is on main" "main" "$(git -C "$d/worktrees/main" branch --show-current)"
for sd in data notes scratch bin; do
  assert_ok "scaffolded $sd/" test -d "$d/$sd"
done
assert_ok "HYPER.md written" test -f "$d/HYPER.md"
assert_ok "memory seed written" test -f "$d/.hyper/memory/hyper-layout.md"
assert_ok "space settings written" test -f "$d/.claude/settings.json"
assert_eq "worktrunk default branch recorded" "main" \
  "$(git --git-dir="$d/.git" config worktrunk.default-branch)"
assert_fails "no origin remote configured" \
  git --git-dir="$d/.git" config --get remote.origin.url
assert_contains "next steps mention adding a remote later" "$out" "remote add origin"

# M2: a space is detected as such, and adopt on it is a case-A no-op
assert_eq "space_layout accepts the new space" "bare" \
  "$(bash -c "source '$SCRIPTS_DIR/hyper-lib.sh'; space_layout '$d'")"
out="$(bash "$SCRIPTS_DIR/hyper-adopt.sh" "$d" --apply 2>&1)"
assert_eq "adopt on the new space exits 0" 0 "$?"
assert_not_contains "adopt does not try to convert it" "$out" "Converting"

# M3: --new with a custom default branch
( cd "$FIX" && PATH="$clean_path" bash "$INIT" --new proj2 --default-branch trunk ) >/dev/null 2>&1
assert_eq "custom branch worktree" "trunk" \
  "$(git -C "$FIX/proj2/worktrees/trunk" branch --show-current)"

# M4: refusals
out="$( (cd "$FIX" && bash "$INIT" --new proj) 2>&1 )"
rc=$?
assert_eq "existing path refused" 1 "$rc"
assert_contains "refusal names the path" "$out" "refusing to overwrite"

out="$( (cd "$FIX" && bash "$INIT" --new a b) 2>&1 )"
rc=$?
assert_eq "--new with two positionals exits 2" 2 "$rc"

out="$( (cd "$FIX" && bash "$INIT" --new) 2>&1 )"
rc=$?
assert_eq "--new without a name exits 2" 2 "$rc"

out="$( (cd "$FIX" && bash "$INIT") 2>&1 )"
rc=$?
assert_eq "no arguments exits 2" 2 "$rc"
assert_contains "usage shows the --new form" "$out" "--new"

# M6: --multi builds an empty multi-repo space
out="$( (cd "$FIX" && PATH="$clean_path" bash "$INIT" --multi mspace) 2>&1 )"
rc=$?
md="$FIX/mspace"
assert_eq "--multi exits 0" 0 "$rc"
assert_fails "no .git at multi-repo root" test -e "$md/.git"
assert_ok "code/ dir created" test -d "$md/code"
for sd in data notes scratch bin; do
  assert_ok "multi scaffolded $sd/" test -d "$md/$sd"
done
assert_fails "multi space has no root worktrees/" test -d "$md/worktrees"
assert_ok "multi HYPER.md written" test -f "$md/HYPER.md"
assert_contains "multi HYPER.md documents multi-repo layout" "$(cat "$md/HYPER.md")" "multi-repo layout"
assert_ok "multi memory seed written" test -f "$md/.hyper/memory/hyper-layout.md"

# M6b: --slug as the very first repo of a fresh --multi space, run from the
# root. space_layout now recognizes an empty --multi space on its own (marker
# + no .git + code/ dir, no repo required), so find_space_root/space_layout
# — not a manual walk — must resolve this correctly with zero repos present.
out="$( (cd "$FIX" && PATH="$clean_path" bash "$INIT" --multi firstroot) 2>&1 )"
fr="$FIX/firstroot"
out="$( (cd "$fr" && PATH="$clean_path" bash "$INIT" --new solo --slug solo) 2>&1 )"
assert_eq "first --slug from a fresh --multi space's root exits 0" 0 "$?"
assert_ok "code/solo created as the space's first repo" test -d "$fr/code/solo"
assert_eq "space_layout recognizes it as multi once populated" "multi" \
  "$(bash -c "source '$SCRIPTS_DIR/hyper-lib.sh'; space_layout '$fr'")"

# M6c: same, but the very first --slug is run from a local-only dir (notes/)
# rather than the space root, before any repo exists anywhere in the space.
out="$( (cd "$FIX" && PATH="$clean_path" bash "$INIT" --multi firstnotes) 2>&1 )"
fn="$FIX/firstnotes"
mkdir -p "$fn/notes"
out="$( (cd "$fn/notes" && PATH="$clean_path" bash "$INIT" --new solo --slug solo) 2>&1 )"
assert_eq "first --slug from notes/ of a fresh --multi space exits 0" 0 "$?"
assert_ok "code/solo created from notes/ as the space's first repo" test -d "$fn/code/solo"

# M7: --slug adds a repo, from the space root
out="$( (cd "$md" && PATH="$clean_path" bash "$INIT" --new alpha --slug alpha) 2>&1 )"
rc=$?
assert_eq "--slug (root) exits 0" 0 "$rc"
assert_eq "code/alpha is bare" "true" \
  "$(git --git-dir="$md/code/alpha/.git" config --get core.bare)"
assert_ok "code/alpha worktree created" test -d "$md/code/alpha/worktrees/main"
assert_eq "space_layout now says multi" "multi" \
  "$(bash -c "source '$SCRIPTS_DIR/hyper-lib.sh'; space_layout '$md'")"
hyper_md="$(cat "$md/HYPER.md")"
assert_contains "HYPER.md gained an alpha row" "$hyper_md" '`alpha`'

# M8: --slug from a local-only dir (notes/) inside the space
mkdir -p "$md/notes"
out="$( (cd "$md/notes" && PATH="$clean_path" bash "$INIT" --new beta --slug beta) 2>&1 )"
assert_eq "--slug (notes/) exits 0" 0 "$?"
assert_ok "code/beta created from notes/" test -d "$md/code/beta"
hyper_md="$(cat "$md/HYPER.md")"
assert_contains "HYPER.md gained a beta row" "$hyper_md" '`beta`'
assert_eq "no duplicate alpha row" 1 \
  "$(grep -cF '| `alpha` |' "$md/HYPER.md")"

# M9: --slug from inside an existing repo's worktree
out="$( (cd "$md/code/alpha/worktrees/main" && PATH="$clean_path" bash "$INIT" --new gamma --slug gamma) 2>&1 )"
assert_eq "--slug (inside code/alpha/worktrees/main) exits 0" 0 "$?"
assert_ok "code/gamma created from inside another repo's worktree" test -d "$md/code/gamma"

# M10: --slug outside a multi space fails
out="$( (cd "$FIX" && PATH="$clean_path" bash "$INIT" --new delta --slug delta) 2>&1 )"
rc=$?
assert_eq "--slug outside a multi space exits non-zero" 1 "$rc"
assert_contains "refusal explains no multi-repo space found" "$out" "not inside a multi-repo space"

# M11: --slug inside a bare (single-repo) space fails
out="$( (cd "$d" && PATH="$clean_path" bash "$INIT" --new delta --slug delta) 2>&1 )"
rc=$?
assert_eq "--slug inside a bare space exits non-zero" 1 "$rc"
assert_contains "refusal names bare space" "$out" "bare (single-repo) space"

# M12: duplicate slug fails
out="$( (cd "$md" && PATH="$clean_path" bash "$INIT" --new alpha2 --slug alpha) 2>&1 )"
rc=$?
assert_eq "duplicate slug exits non-zero" 1 "$rc"
assert_contains "duplicate slug refusal names it" "$out" "code/alpha already exists"

# M13: invalid slug fails
out="$( (cd "$md" && PATH="$clean_path" bash "$INIT" --new zed --slug ZED) 2>&1 )"
rc=$?
assert_eq "invalid slug exits 2" 2 "$rc"

# M5: missing git identity refuses BEFORE creating anything
env_home="$FIX/no-ident-home"
mkdir -p "$env_home"
out="$( (cd "$FIX" && HOME="$env_home" GIT_CONFIG_GLOBAL="$env_home/.gitconfig" \
  PATH="$clean_path" bash "$INIT" --new proj3) 2>&1 )"
rc=$?
assert_eq "missing identity exits 1" 1 "$rc"
assert_contains "identity refusal explains the fix" "$out" "user.name"
assert_fails "nothing was created" test -e "$FIX/proj3"

finish
