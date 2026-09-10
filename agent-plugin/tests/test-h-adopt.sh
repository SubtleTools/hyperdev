#!/usr/bin/env bash
# Row H — adopt's dry-run suggestion matrix. The dangerous cases must be
# do-not-move; the mundane stray gets filed under data/. And a dry run must
# change nothing.

source "$(dirname "${BASH_SOURCE[0]}")/helpers.sh"
set +eu
set +o pipefail

ADOPT="$SCRIPTS_DIR/hyper-adopt.sh"

d="$FIX/h1"; make_bare_space "$d"
touch "$d/HYPER.md"
# a live SQLite database (the -wal sidecar is the liveness signal)
echo 'not-a-real-db' > "$d/app.sqlite"
echo 'wal'           > "$d/app.sqlite-wal"
# a tool-managed directory whose location is a contract with the toolchain
mkdir -p "$d/node_modules/left-pad"
# a mundane stray archive
echo 'zip' > "$d/archive.zip"

out="$(bash "$ADOPT" "$d" 2>&1)"
rc=$?
assert_eq "dry run exits 0" 0 "$rc"
assert_contains "output confirms this was a dry run" "$out" "Dry run"

# H1: .sqlite with a -wal sidecar -> live database, do not move
sqlite_line="$(printf '%s\n' "$out" | grep -F 'app.sqlite ')"
assert_contains "live sqlite flagged as LIVE database" "$sqlite_line" "LIVE database"
assert_contains "live sqlite says do not move"         "$sqlite_line" "do not move"

# H2: node_modules -> tool-managed, leave in place
nm_line="$(printf '%s\n' "$out" | grep -F 'node_modules')"
assert_contains "node_modules flagged tool-managed" "$nm_line" "tool-managed"
assert_contains "node_modules must never be moved"  "$nm_line" "never move"

# H3: stray .zip -> data/
zip_line="$(printf '%s\n' "$out" | grep -F 'archive.zip')"
assert_contains "stray zip suggested for data/" "$zip_line" "data/"

# A dry run changes nothing on disk
assert_fails "dry run scaffolds no directories" test -d "$d/data"
assert_fails "dry run writes no memory seed"    test -e "$d/.hyper"
assert_fails "dry run writes no settings"       test -e "$d/.claude/settings.json"

# H4: adopt on a multi-repo shaped directory scaffolds without root worktrees/
md="$FIX/h2"
make_multi_space "$md" alpha beta

out="$(bash "$ADOPT" "$md" --apply 2>&1)"
rc=$?
assert_eq "adopt --apply on multi-shaped dir exits 0" 0 "$rc"
assert_contains "adopt reports multi layout" "$out" "Layout:    multi"
for sd in data notes scratch bin; do
  assert_ok "adopt scaffolded $sd/" test -d "$md/$sd"
done
assert_fails "adopt did not create root worktrees/" test -d "$md/worktrees"
# make_multi_space pre-creates an empty HYPER.md marker (needed for the
# fixture's own multi-repo shape to be discoverable at all), so adopt must
# leave it untouched here rather than overwrite it with the multi template.
assert_contains "adopt leaves pre-existing HYPER.md untouched" "$out" "HYPER.md (left untouched)"
assert_ok "adopt wrote memory seed" test -f "$md/.hyper/memory/hyper-layout.md"

# Re-running adopt is a no-op on the parts already there
out2="$(bash "$ADOPT" "$md" --apply 2>&1)"
assert_contains "re-adopt leaves HYPER.md untouched" "$out2" "HYPER.md (left untouched)"

# H5: same shape but with no pre-existing HYPER.md — adopt's multi-shape
# scan only needs code/*/.git (bare), not the marker, so it still recognizes
# the shape and writes the real multi template fresh.
md2="$FIX/h3"
make_multi_space "$md2" gamma
rm "$md2/HYPER.md"

out3="$(bash "$ADOPT" "$md2" --apply 2>&1)"
assert_eq "adopt on multi-shaped dir with no marker exits 0" 0 "$?"
assert_contains "adopt writes fresh HYPER.md" "$out3" "wrote    HYPER.md"
assert_contains "fresh HYPER.md documents multi-repo layout" \
  "$(cat "$md2/HYPER.md")" "multi-repo layout"
assert_contains "fresh HYPER.md lists the gamma repo" "$(cat "$md2/HYPER.md")" '`gamma`'

finish
