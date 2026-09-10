#!/usr/bin/env bash
# Adopt a repository into the hyper space layout.
# Usage: hyper-adopt.sh [path] [--apply]
#
# Two cases at the target path:
#
#   bare repo / existing space   scaffold what is missing, report loose
#                                entries. Project files are never moved.
#
#   ordinary checkout            CONVERT it: the repo becomes bare, the whole
#                                working tree moves to worktrees/<branch>, and
#                                the space structure is built around it. Space
#                                files and project files never share a
#                                directory, so decorating the checkout is not
#                                an option — wrapping it is.
#
# Without --apply nothing changes; conversion prints its full plan first.
# Nothing is ever deleted, in any mode, on any path.

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/hyper-lib.sh"

root=""
apply=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --apply) apply=1; shift ;;
    -*) echo "unknown flag: $1" >&2; exit 2 ;;
    *) root="$1"; shift ;;
  esac
done

if [[ -z "$root" ]]; then
  root="$(find_space_root "$PWD")" || root="$PWD"
fi

root="$(cd "$root" && pwd)"
name="$(basename "$root")"

# ===========================================================================
# Case C: already multi-repo shaped (code/*/.git bare, no .git at the root).
# Converting a single-repo checkout INTO a multi-repo space is out of scope —
# this only recognizes a root that is already laid out that way and scaffolds
# what is missing. Checked before the git-repository checks below, since a
# multi-repo root is deliberately not a git repository at all.
# ===========================================================================
multi_shaped=0
if [[ ! -e "$root/.git" ]] && [[ -d "$root/code" ]]; then
  # nullglob so an empty code/ expands to nothing rather than the literal
  # pattern string falling through to the -d test below.
  shopt -q nullglob && multi_nullglob_was_set=1 || multi_nullglob_was_set=0
  shopt -s nullglob
  multi_repo_candidates=("$root"/code/*/)
  [[ $multi_nullglob_was_set -eq 1 ]] || shopt -u nullglob
  for r in "${multi_repo_candidates[@]+"${multi_repo_candidates[@]}"}"; do
    [[ -d "$r/.git" ]] || continue
    if [[ "$(git --git-dir="$r/.git" config --get core.bare 2>/dev/null)" == "true" ]]; then
      multi_shaped=1
      break
    fi
  done
fi

if [[ $multi_shaped -eq 1 ]]; then
  echo "Space: $root"
  echo "Layout:    multi"
  echo

  if [[ $apply -eq 1 ]]; then
    # Marker before scaffold: space_layout (and so scaffold_dirs's own
    # auto-detection of "no root worktrees/") needs HYPER.md + code/ to
    # recognize the multi shape; write it first so detection works below
    # even when this is the very first time this root is scaffolded.
    mkdir -p "$root/.claude"
    if [[ -f "$root/HYPER.md" ]]; then
      echo "  exists   HYPER.md (left untouched)"
    else
      write_hyper_md_multi "$root" "$name"
      echo "  wrote    HYPER.md"
    fi
    echo "Directories:"
    scaffold_dirs "$root"
    ensure_agent_docs "$root" "$name"
    if [[ -f "$root/.hyper/memory/hyper-layout.md" ]]; then
      echo "  exists   .hyper/memory/hyper-layout.md (left untouched)"
    else
      write_memory_seed "$root" "$name"
      echo "  wrote    .hyper/memory/hyper-layout.md"
    fi
    local_slug=""
    for local_slug in $(space_repos "$root" 2>/dev/null || true); do
      [[ -n "$local_slug" ]] || continue
      branch="$(git --git-dir="$root/code/$local_slug/.git" symbolic-ref --short HEAD 2>/dev/null || echo main)"
      ensure_worktrunk_config "$root/code/$local_slug/.git" "$branch"
    done
    echo
    echo "Scaffold applied."
    echo
    echo "Next steps:"
    echo "  /hyper:tools   wire the project's linter/typechecker into the check hook"
    echo "  /hyper:audit   periodic health report (drift, debris, stale branches)"
  else
    echo "Directories (dry run):"
    for d in data notes scratch bin; do
      if [[ -d "$root/$d" ]]; then
        echo "  exists   $d/"
      else
        echo "  would create  $d/  — $(dir_purpose "$d")"
      fi
    done
    if [[ -f "$root/HYPER.md" ]]; then
      echo "  exists   HYPER.md"
    else
      echo "  would create  HYPER.md (multi-repo layout)"
    fi
    for agent_doc in AGENTS.md CLAUDE.md; do
      if [[ -L "$root/$agent_doc" ]]; then
        echo "  exists   $agent_doc (symlink)"
      elif [[ -f "$root/$agent_doc" ]]; then
        echo "  exists   $agent_doc"
      else
        echo "  would create  $agent_doc"
      fi
    done
    echo
    echo "Dry run. Re-run with --apply to create directories and docs."
  fi
  exit 0
fi

# adopt is the command that performs the opt-in, so it must accept a plain
# repository that space_layout would still reject. Any git root qualifies;
# detection tightens again once the marker exists.
if ! git -C "$root" rev-parse --git-dir >/dev/null 2>&1; then
  echo "not a git repository: $root" >&2
  echo "pass a path explicitly, or use hyper-init.sh to create a space" >&2
  exit 1
fi

if [[ ! -d "$root/.git" ]]; then
  echo "not a repository root: $root" >&2
  echo "this looks like a linked worktree; adopt the space it belongs to" >&2
  exit 1
fi

# ---------------------------------------------------------------------------
# Shared reporting: the loose-entry scan against a bare space root, and the
# worktrees/ debris scan. Used by case A and by case B after conversion.
# ---------------------------------------------------------------------------

report_loose_entries() {
  local r="$1"
  echo "Loose entries at space root (suggestions only — nothing is moved):"

  local found_loose=0 entry base skip d suggestion size gitdir
  while IFS= read -r entry; do
    base="$(basename "$entry")"

    # Skip the structural pieces and the directories we manage.
    case "$base" in
      .git|.gitignore|.claude|.hyper|HYPER.md|.DS_Store) continue ;;
      # Legacy (pre-rename) names: ours, not strays. adopt --apply migrates
      # them, so the report points there instead of suggesting a move.
      HYPERDEV.md|.hyperdev)
        suggestion="HYPER.md"
        [[ "$base" == .hyperdev ]] && suggestion=".hyper/"
        printf '  %-32s %6s  → %s\n' "$base" "" \
          "legacy (pre-rename) name — adopt --apply migrates it to $suggestion"
        found_loose=1
        continue ;;
      # Our own conversion-verification evidence. Moving it to data/ would
      # enshrine debris; the right remedy is reconcile, then delete.
      .hyper-convert.preflight|.hyperdev-convert.preflight)
        size="$(du -sh "$entry" 2>/dev/null | cut -f1 || echo '?')"
        printf '  %-32s %6s  → %s\n' "$base" "$size" \
          "conversion evidence (a conversion did not verify cleanly) — reconcile, then delete; do not file away"
        found_loose=1
        continue ;;
    esac

    # /hyper:gen keeps templates at <space>/templates/, so that directory
    # is managed, not a stray.
    [[ "$base" == templates && -d "$entry" ]] && continue

    skip=0
    for d in "${SPACE_DIRS[@]}"; do
      [[ "$base" == "$d" ]] && skip=1 && break
    done
    [[ $skip -eq 1 ]] && continue

    found_loose=1

    # Suggest a destination by shape: big binaries and dumps to data/,
    # markdown and docs to notes/, executables to bin/, rest unclassified.
    suggestion=""
    if [[ -e "$entry/.git" ]]; then
      # A checkout sitting at the space root — never a data/ or notes/ file.
      # Distinguish a live worktree from an orphan whose registration git has
      # already pruned, because the remedies are opposite.
      if [[ -f "$entry/.git" ]] \
         && gitdir="$(sed -n 's/^gitdir: //p' "$entry/.git" 2>/dev/null)" \
         && [[ -n "$gitdir" ]] && [[ ! -d "$gitdir" ]]; then
        suggestion="ORPHANED worktree (gitdir missing) — recover or delete; do NOT move"
      else
        suggestion="git checkout — belongs in worktrees/; move with git worktree, not mv"
      fi
      size="$(du -sh "$entry" 2>/dev/null | cut -f1 || echo '?')"
      printf '  %-32s %6s  → %s\n' "$base" "$size" "$suggestion"
      continue
    fi

    # A live database must not be moved: connection strings routinely use a
    # relative path, so moving it silently creates a fresh empty database
    # instead of failing loudly.
    case "$base" in
      *.sqlite|*.sqlite3|*.db|*.duckdb)
        size="$(du -sh "$entry" 2>/dev/null | cut -f1 || echo '?')"
        # Existence test, not compgen -G: a glob would let [ ? * in the DB's
        # own filename defeat (or false-positive) the liveness check.
        if [[ -e "$entry-wal" || -e "$entry-shm" ]]; then
          printf '  %-32s %6s  → %s\n' "$base" "$size" \
            "LIVE database (has -wal/-shm) — do not move; check the app's connection path first"
        else
          printf '  %-32s %6s  → %s\n' "$base" "$size" \
            "database — move to data/ only after confirming no relative path points here"
        fi
        continue ;;
    esac

    # Tool-managed directories and local secrets must stay exactly where they
    # are: their location is part of a contract with a package manager, build
    # tool, or runtime. Moving them breaks the project.
    case "$base" in
      node_modules|.turbo|.cache|.next|.nuxt|.svelte-kit|dist|build|out|coverage|target|vendor|.venv|venv|__pycache__|.pytest_cache|.gradle|.angular|.parcel-cache|.vite)
        size="$(du -sh "$entry" 2>/dev/null | cut -f1 || echo '?')"
        printf '  %-32s %6s  → %s\n' "$base" "$size" \
          "tool-managed — leave in place (delete to reclaim space, never move)"
        continue ;;
      .env|.env.*|*.pem|*.key|id_rsa|id_ed25519|.npmrc|.netrc)
        size="$(du -sh "$entry" 2>/dev/null | cut -f1 || echo '?')"
        printf '  %-32s %6s  → %s\n' "$base" "$size" \
          "local secrets — leave in place; tools read this exact path"
        continue ;;
    esac

    if [[ -d "$entry" ]]; then
      case "$base" in
        # An unrecognized dot-directory is usually another tool's state (plugin
        # caches, agent workspaces); moving it orphans it. The known-safe dot
        # names were already handled by the tool-managed list above.
        .*) suggestion="dot-directory — likely tool or plugin state; leave in place unless you know its owner" ;;
        *data*|*fixtures*|*dump*|*db*) suggestion="data/" ;;
        *doc*|*note*|*handoff*|*brief*) suggestion="notes/" ;;
        *bin|*scripts*)                 suggestion="bin/" ;;
        *result*|*report*|*output*)     suggestion="scratch/ (regenerated output)" ;;
        *)                              suggestion="notes/ or data/ (inspect contents)" ;;
      esac
    else
      case "$base" in
        # SQLite sidecars are live database state, not disposable scratch.
        *.sqlite-shm|*.sqlite-wal|*.db-shm|*.db-wal)
          suggestion="live DB sidecar — move only alongside its .sqlite/.db" ;;
        *.sql|*.csv|*.dump|*.tar|*.tar.gz|*.zip|*.parquet|*.db|*.sqlite|*dump*) suggestion="data/" ;;
        *.md|*.txt|*.pdf)                                                suggestion="notes/" ;;
        *.sh|*.py|*.rb)                                                  suggestion="bin/" ;;
        *)
          # Unrecognized extension: size decides. A big blob is data until
          # proven disposable (audit draws the same 10MB line — the two
          # commands must not give the same file opposite destinations).
          if [[ -n "$(find "$entry" -maxdepth 0 -size +10M 2>/dev/null)" ]]; then
            suggestion="data/ (large blob) — or scratch/ only if truly disposable"
          else
            suggestion="scratch/ if disposable"
          fi ;;
      esac
    fi

    size="$(du -sh "$entry" 2>/dev/null | cut -f1 || echo '?')"
    printf '  %-32s %6s  → %s\n' "$base" "$size" "$suggestion"
  done < <(find "$r" -mindepth 1 -maxdepth 1)

  if [[ $found_loose -eq 0 ]]; then
    echo "  (none)"
  fi
  return 0
}

report_worktree_dir() {
  local r="$1"
  # The loose-file scan is maxdepth 1, so debris *inside* the worktrees
  # directory never surfaces. Dead checkouts accumulate there — a removed
  # worktree leaves build output behind, and it looks like a live branch until
  # you inspect it.
  local wt_scan="$r/worktrees"
  [[ -d "$wt_scan" ]] || return 0
  echo
  echo "Worktree directory (worktrees/):"
  local wt_found=0 w wname wsize wgd wbranch
  for w in "$wt_scan"/*/; do
    [[ -d "$w" ]] || continue
    wname="$(basename "$w")"
    wt_found=1
    if [[ ! -e "$w/.git" ]]; then
      wsize="$(du -sh "$w" 2>/dev/null | cut -f1 || echo '?')"
      printf '  %-32s %6s  → %s\n' "$wname" "$wsize" \
        "no .git — leftover build output, not a worktree; safe to delete"
    elif [[ -f "$w/.git" ]] \
         && wgd="$(sed -n 's/^gitdir: //p' "$w/.git" 2>/dev/null)" \
         && [[ -n "$wgd" && ! -d "$wgd" ]]; then
      wsize="$(du -sh "$w" 2>/dev/null | cut -f1 || echo '?')"
      printf '  %-32s %6s  → %s\n' "$wname" "$wsize" \
        "ORPHANED — gitdir missing; recover or delete"
    else
      wbranch="$(git -C "$w" branch --show-current 2>/dev/null || echo '?')"
      printf '  %-32s %6s  → %s\n' "$wname" "" "ok [$wbranch]"
    fi
  done
  [[ $wt_found -eq 0 ]] && echo "  (empty)"
  return 0
}

# Legacy (pre-rename) artifact names. adopt --apply migrates them to the new
# names — each move announced, nothing ever deleted. When old and new both
# exist we cannot know which one is truth, so we warn and touch neither.
# .claude/hyperdev.json is deliberately NOT auto-renamed: it may be committed
# project config in a worktree; the hooks' fallback keeps it working.
migrate_legacy_names() {
  local r="$1"
  if [[ -f "$r/HYPERDEV.md" ]]; then
    if [[ -f "$r/HYPER.md" ]]; then
      echo "  warning  both HYPER.md and legacy HYPERDEV.md exist — touching neither; reconcile them yourself"
    else
      mv "$r/HYPERDEV.md" "$r/HYPER.md"
      echo "  migrated HYPERDEV.md → HYPER.md (legacy marker renamed)"
    fi
  fi
  if [[ -d "$r/.hyperdev" ]]; then
    if [[ -d "$r/.hyper" ]]; then
      echo "  warning  both .hyper/ and legacy .hyperdev/ exist — touching neither; merge them yourself"
    else
      mv "$r/.hyperdev" "$r/.hyper"
      echo "  migrated .hyperdev/ → .hyper/ (legacy metadata dir renamed)"
    fi
  fi
  # The old memory seed name inside the (possibly just-migrated) metadata dir:
  # left in place it would stay wired as a stale duplicate memory.
  local mem="$r/.hyper/memory"
  if [[ -f "$mem/hyperdev-layout.md" ]]; then
    if [[ -f "$mem/hyper-layout.md" ]]; then
      echo "  warning  both hyper-layout.md and legacy hyperdev-layout.md exist in .hyper/memory/ — touching neither"
    else
      mv "$mem/hyperdev-layout.md" "$mem/hyper-layout.md"
      echo "  migrated .hyper/memory/hyperdev-layout.md → hyper-layout.md"
      if grep -q 'hyperdev-layout.md' "$mem/MEMORY.md" 2>/dev/null; then
        grep -v 'hyperdev-layout.md' "$mem/MEMORY.md" > "$mem/MEMORY.md.tmp" || :
        mv "$mem/MEMORY.md.tmp" "$mem/MEMORY.md"
        printf -- '- [Space layout](hyper-layout.md) — worktrees/, local-only dirs, root is never committed\n' >> "$mem/MEMORY.md"
        echo "  updated  .hyper/memory/MEMORY.md (index line points at hyper-layout.md)"
      fi
    fi
  fi
  return 0
}

scaffold_space() {
  local r="$1" n="$2"
  local branch
  branch="$(git --git-dir="$r/.git" symbolic-ref --short HEAD 2>/dev/null || echo main)"
  ensure_worktrunk_config "$r/.git" "$branch"
  echo "Directories:"
  scaffold_dirs "$r"
  mkdir -p "$r/.claude"
  # Additive only, as the docs promise: these files are the user's to edit
  # once they exist, so a re-adopt must never regenerate over their changes.
  if [[ -f "$r/HYPER.md" ]]; then
    echo "  exists   HYPER.md (left untouched)"
  else
    write_hyper_md "$r" "$n"
    echo "  wrote    HYPER.md"
  fi
  ensure_agent_docs "$r" "$n"
  if [[ -f "$r/.hyper/memory/hyper-layout.md" ]]; then
    echo "  exists   .hyper/memory/hyper-layout.md (left untouched)"
  else
    write_memory_seed "$r" "$n"
    echo "  wrote    .hyper/memory/hyper-layout.md"
  fi
}

# ===========================================================================
# Case A: already bare (a space, or a plain bare repo opting in).
# ===========================================================================

if [[ "$(git --git-dir="$root/.git" config --get core.bare 2>/dev/null)" == "true" ]]; then
  echo "Space: $root"
  echo "Layout:    bare"
  echo

  if [[ $apply -eq 1 ]]; then
    migrate_legacy_names "$root"
    scaffold_space "$root" "$name"
  else
    echo "Directories (dry run):"
    for d in "${SPACE_DIRS[@]}"; do
      if [[ -d "$root/$d" ]]; then
        echo "  exists   $d/"
      else
        echo "  would create  $d/  — $(dir_purpose "$d")"
      fi
    done
    if [[ -f "$root/HYPER.md" ]]; then
      echo "  exists   HYPER.md"
      [[ -f "$root/HYPERDEV.md" ]] \
        && echo "  warning  legacy HYPERDEV.md also exists — --apply touches neither; reconcile them yourself"
    elif [[ -f "$root/HYPERDEV.md" ]]; then
      echo "  would migrate  HYPERDEV.md → HYPER.md (legacy marker)"
    else
      echo "  would create  HYPER.md"
    fi
    for agent_doc in AGENTS.md CLAUDE.md; do
      if [[ -L "$root/$agent_doc" ]]; then
        echo "  exists   $agent_doc (symlink)"
      elif [[ -f "$root/$agent_doc" ]]; then
        if grep -q 'HYPER\.md' "$root/$agent_doc" 2>/dev/null; then
          echo "  exists   $agent_doc (already references HYPER.md)"
        else
          echo "  would update  $agent_doc (append hyper space section)"
        fi
      else
        echo "  would create  $agent_doc (symlink)"
      fi
    done
    if [[ -d "$root/.hyperdev" ]]; then
      if [[ -d "$root/.hyper" ]]; then
        echo "  warning  both .hyper/ and legacy .hyperdev/ exist — --apply touches neither; merge them yourself"
      else
        echo "  would migrate  .hyperdev/ → .hyper/ (legacy metadata dir)"
      fi
    fi
  fi

  echo
  report_loose_entries "$root"
  report_worktree_dir "$root"

  echo
  if [[ $apply -eq 1 ]]; then
    echo "Scaffold applied. Move loose entries yourself — the suggestions above are"
    echo "heuristics, and only you know which files still matter."
    echo
    echo "Next steps:"
    echo "  /hyper:tools   wire the project's linter/typechecker into the check hook"
    echo "  /hyper:audit   periodic health report (drift, debris, stale branches)"
  else
    echo "Dry run. Re-run with --apply to create directories and docs."
  fi
  exit 0
fi

# ===========================================================================
# Case B: an ordinary checkout. Convert it into a bare space.
# ===========================================================================

staging="$root/.hyper-convert"

# --- preflight -------------------------------------------------------------
# Every refusal is collected so the dry run can show all of them at once;
# --apply refuses on any. Nothing below this block runs before they pass.

refusals=()

branch="$(git -C "$root" symbolic-ref --short HEAD 2>/dev/null)" || {
  branch=""
  refusals+=("detached HEAD — check out a branch first")
}

g="$root/.git"
[[ -e "$g/rebase-merge" || -e "$g/rebase-apply" ]] \
  && refusals+=("rebase in progress — finish or abort it first")
[[ -e "$g/MERGE_HEAD" ]] \
  && refusals+=("merge in progress — finish or abort it first")
[[ -e "$g/CHERRY_PICK_HEAD" ]] \
  && refusals+=("cherry-pick in progress — finish or abort it first")

# Submodule gitdir pointers are written relative to the superproject's .git
# and do not survive the depth change to worktrees/<branch>/. Converting
# would leave every submodule pointing at a path that no longer resolves.
[[ -e "$root/.gitmodules" ]] \
  && refusals+=(".gitmodules present — submodule gitdir pointers do not survive the depth change; deinit submodules first")

case "$PWD" in
  "$root"|"$root"/*)
    refusals+=("current directory is inside the repo being converted — cd out of $root first") ;;
esac

# Data-safety pre-capture doubles as a readability check: a ref or stash we
# cannot read is a ref we cannot guarantee, so a failing read is a refusal.
pre_refs=""
if ! pre_refs="$(git -C "$root" for-each-ref --format='%(refname) %(objectname)' 2>/dev/null)"; then
  refusals+=("cannot read refs (git for-each-ref failed) — cannot guarantee they survive")
fi
pre_stash_count=0
if ! _stash_list="$(git -C "$root" stash list 2>/dev/null)"; then
  refusals+=("git stash list failed — cannot guarantee stashes survive")
else
  [[ -n "$_stash_list" ]] && pre_stash_count="$(wc -l <<<"$_stash_list" | tr -d ' ')"
fi
pre_stash_hash="$(git -C "$root" rev-parse -q --verify refs/stash 2>/dev/null || echo none)"

# An unmerged index has three stages per conflicted path; `reset` in the new
# worktree would flatten that state. Stop rather than lose it.
[[ -n "$(git -C "$root" ls-files -u 2>/dev/null | head -n1)" ]] \
  && refusals+=("unmerged/conflicted index entries — resolve or abort the conflict first")

# The scaffold creates these as directories; a *file* with one of the names
# would end up shadowed by its space-root namesake.
for d in "${SPACE_DIRS[@]}"; do
  [[ -e "$root/$d" && ! -d "$root/$d" ]] \
    && refusals+=("a file named '$d' at the root collides with the scaffolded $d/ directory — rename it first")
done

[[ -w "$root" ]] \
  || refusals+=("no write permission on $root")

[[ -e "$staging" ]] \
  && refusals+=(".hyper-convert already exists — a previous conversion did not finish; resolve it first")
[[ -e "$root/.hyperdev-convert" ]] \
  && refusals+=(".hyperdev-convert already exists — a pre-rename conversion did not finish; resolve it first")

branch_dir=""
if [[ -n "$branch" ]]; then
  branch_dir="${branch//\//-}"
  [[ -e "$root/worktrees/$branch_dir" ]] \
    && refusals+=("worktrees/$branch_dir already exists — remove or rename it first")
fi

# --- pre-state capture -----------------------------------------------------

pre_state="$(git -C "$root" status --porcelain=v1 2>/dev/null)" || pre_state=""
wt_list="$(git -C "$root" worktree list --porcelain 2>/dev/null)" || wt_list=""

# Full file inventory (relative paths, .git pruned). Postflight proves every
# one of these paths still exists somewhere — set comparison, not a count.
pre_inventory="$(cd "$root" && find . -mindepth 1 -path ./.git -prune -o -print \
                 | sed 's|^\./||' | LC_ALL=C sort)"
pre_inv_count="$(printf '%s' "$pre_inventory" | grep -c . || :)"

# Pre-existing linked worktrees (skip the first stanza — the main worktree,
# which is $root itself and becomes worktrees/<branch>). Each moved worktree
# is named after its branch, like everything else under worktrees/; the path
# basename is only a fallback for a detached one.
linked_worktrees=()
linked_wt_names=()
cur_path="" cur_branch="" stanza=0
flush_wt_stanza() {
  [[ -n "$cur_path" ]] || return 0
  stanza=$((stanza + 1))
  if [[ $stanza -gt 1 ]]; then
    local n="${cur_branch:-$(basename "$cur_path")}"
    linked_worktrees+=("$cur_path")
    linked_wt_names+=("${n//\//-}")
  fi
  cur_path="" cur_branch=""
}
while IFS= read -r line; do
  case "$line" in
    "worktree "*) flush_wt_stanza; cur_path="${line#worktree }" ;;
    "branch refs/heads/"*) cur_branch="${line#branch refs/heads/}" ;;
  esac
done <<< "$wt_list"
flush_wt_stanza

# --- classify every root entry ---------------------------------------------
# Destinations: the new worktree (project files), the space root (what was
# space-local under the old checkout design), or a worktree move (step 8).

# Space-local dirs stay only when git tracks nothing inside them; a tracked
# data/ is project content and belongs with the project.
dir_is_space_local() {
  local d="$1"
  [[ -d "$root/$d" ]] || return 1
  [[ -z "$(git -C "$root" ls-files --cached -- "$d" | head -n1)" ]]
}

keep_space=()      # top-level entries kept aside for the space root
to_worktree=()     # top-level entries staged for the new worktree
claude_split=0     # .claude needs the per-entry split described below

while IFS= read -r entry; do
  base="$(basename "$entry")"
  case "$base" in
    .git) continue ;;
    .hyper-convert) continue ;;   # refused above; never classify it
    .claude) claude_split=1; continue ;;
    HYPER.md|HYPERDEV.md)
      if git -C "$root" ls-files --error-unmatch "$base" >/dev/null 2>&1; then
        to_worktree+=("$base")       # tracked: project content
      else
        keep_space+=("$base")        # untracked marker: regenerated anyway
      fi
      continue ;;
    data|notes|scratch|bin|.hyper|.hyperdev)
      if dir_is_space_local "$base"; then
        keep_space+=("$base")
      else
        to_worktree+=("$base")
      fi
      continue ;;
  esac
  to_worktree+=("$base")
done < <(find "$root" -mindepth 1 -maxdepth 1)

# --- dry run: print the conversion plan ------------------------------------

if [[ $apply -eq 0 ]]; then
  echo "CONVERSION PLAN for $root"
  echo
  echo "This is an ordinary checkout. A space has exactly one shape — bare"
  echo ".git at the root, the working tree in worktrees/ — so adopting this"
  echo "repo means converting it:"
  echo
  echo "  branch:    ${branch:-'(detached — see refusals)'}"
  [[ -n "$branch_dir" ]] && echo "  worktree:  worktrees/$branch_dir/"
  echo
  echo "Every entry at the root moves as follows:"
  for e in "${to_worktree[@]}"; do
    printf '  %-32s → worktrees/%s/\n' "$e" "${branch_dir:-<branch>}"
  done
  for e in "${keep_space[@]}"; do
    printf '  %-32s → stays at the space root (space-local under the old design)\n' "$e"
  done
  if [[ $claude_split -eq 1 ]]; then
    printf '  %-32s → worktrees/%s/.claude (project config)\n' ".claude" "${branch_dir:-<branch>}"
    echo "                                     except memory/hyper-layout.md + its"
    echo "                                     MEMORY.md index line (kept at the space root;"
    echo "                                     the seed is regenerated in .hyper/memory/)"
    echo "                                     and .claude/worktrees/* (moved as worktrees)"
  fi
  for i in "${!linked_worktrees[@]}"; do
    p="${linked_worktrees[$i]}"
    wname="${linked_wt_names[$i]}"
    if [[ "$p" == "$root/worktrees/"* ]]; then
      printf '  %-32s → already under worktrees/, left alone\n' "$p"
    elif [[ ! -e "$p/.git" ]]; then
      printf '  %-32s → ORPHANED worktree (gitdir missing) — will not be touched\n' "$p"
    else
      printf '  %-32s → git worktree move → worktrees/%s/\n' "$p" "$wname"
    fi
  done
  echo
  echo "Then: core.bare=true, scaffold data/ notes/ scratch/ bin/, write"
  echo "HYPER.md and the memory seed (.hyper/memory/), and wire"
  echo "autoMemoryDirectory into .claude/settings.json and the worktree's"
  echo ".claude/settings.local.json. Nothing is deleted at any point."
  echo
  echo "Guarantees verified after conversion (any mismatch is a loud failure, exit 1):"
  echo "  1. every ref (branches, tags, stash) byte-identical"
  echo "  2. stash count and refs/stash hash unchanged ($pre_stash_count stash(es) now)"
  echo "  3. git status in the new worktree identical to the status above conversion"
  echo "  4. every one of the $pre_inv_count pre-conversion paths still on disk"
  echo "     (in the worktree, at the space root, or in a moved worktree)"
  if [[ ${#refusals[@]} -gt 0 ]]; then
    echo
    echo "REFUSALS — --apply would stop on these:"
    for rmsg in "${refusals[@]}"; do
      echo "  - $rmsg"
    done
  fi
  echo
  echo "Dry run. Re-run with --apply to convert."
  exit 0
fi

# --- apply -----------------------------------------------------------------

if [[ ${#refusals[@]} -gt 0 ]]; then
  echo "refusing to convert $root:" >&2
  for rmsg in "${refusals[@]}"; do
    echo "  - $rmsg" >&2
  done
  exit 1
fi

echo "Converting $root (branch: $branch)"

# Evidence file: a crashed run must leave the pre-state on disk, not only in
# the memory of a dead process. Removed only after every guarantee passes.
# Written after the inventory capture, so it is never part of the inventory.
preflight_file="$root/.hyper-convert.preflight"
{
  echo "# hyper-adopt pre-conversion capture: $root"
  echo "# refs"
  printf '%s\n' "$pre_refs"
  echo "# stash count: $pre_stash_count"
  echo "# stash hash: $pre_stash_hash"
  echo "# status --porcelain=v1"
  printf '%s\n' "$pre_state"
  echo "# inventory ($pre_inv_count paths)"
  printf '%s\n' "$pre_inventory"
} > "$preflight_file"

# Any failure past this point must say exactly what remains where. Nothing
# is deleted, so everything needed to finish by hand is still on disk.
on_convert_error() {
  echo >&2
  echo "CONVERSION INCOMPLETE — nothing was deleted." >&2
  if [[ -d "$staging" ]]; then
    echo "Entries still in $staging:" >&2
    find "$staging" -mindepth 1 -maxdepth 1 -exec basename {} \; | sed 's/^/  /' >&2
    echo "To finish by hand: move them into $root/worktrees/$branch_dir/," >&2
    echo "then run: git -C $root/worktrees/$branch_dir reset -q" >&2
  fi
  echo "To abandon: git -C $root config core.bare false, move the staging" >&2
  echo "entries back to $root, and remove the empty staging dir." >&2
  echo "The pre-conversion refs/stash/status/inventory are saved in" >&2
  echo "  $preflight_file" >&2
}
trap on_convert_error ERR

# Step 4: stage everything headed for the worktree. The kept-aside entries
# never enter staging — they simply stay in place at the root.
mkdir -p "$staging"
for e in "${to_worktree[@]}"; do
  mv "$root/$e" "$staging/$e"
done

memory_stripped=0
if [[ $claude_split -eq 1 ]]; then
  mkdir -p "$staging/.claude"
  while IFS= read -r centry; do
    cbase="$(basename "$centry")"
    case "$cbase" in
      worktrees)
        # Entries here are registered linked worktrees — moved with
        # `git worktree move` in step 8, never with mv.
        continue ;;
      memory)
        # hyper-layout.md belongs to the space root (regenerated below);
        # everything else in memory/ is project memory.
        mkdir -p "$staging/.claude/memory"
        while IFS= read -r mentry; do
          mbase="$(basename "$mentry")"
          [[ "$mbase" == hyper-layout.md ]] && continue
          mv "$mentry" "$staging/.claude/memory/$mbase"
        done < <(find "$centry" -mindepth 1 -maxdepth 1)
        continue ;;
      MEMORY.md)
        # The hyper-layout index line belongs to the space root and is
        # regenerated there; the rest of the index is project memory.
        if grep -q 'hyper-layout.md' "$centry" 2>/dev/null; then
          # The stripped copy goes with the project; the original is kept (not
          # deleted) beside the regenerated index at the space root.
          grep -v 'hyper-layout.md' "$centry" > "$staging/.claude/MEMORY.md" || :
          mv "$centry" "$root/.claude/MEMORY.md.hyper-orig"
          memory_stripped=1
        else
          mv "$centry" "$staging/.claude/MEMORY.md"
        fi
        continue ;;
    esac
    mv "$centry" "$staging/.claude/$cbase"
  done < <(find "$root/.claude" -mindepth 1 -maxdepth 1)
fi

# Step 5: make the repository bare and keep fetch behaving like a clone.
git -C "$root" config core.bare true
if git -C "$root" config --get remote.origin.url >/dev/null 2>&1; then
  if ! git -C "$root" config --get-all remote.origin.fetch 2>/dev/null \
       | grep -qxF '+refs/heads/*:refs/remotes/origin/*'; then
    git -C "$root" config --add remote.origin.fetch '+refs/heads/*:refs/remotes/origin/*'
  fi
fi
ensure_worktrunk_config "$root/.git" "$branch"

# Step 6: register the main worktree. --no-checkout because the files arrive
# by move in step 7 — a checkout here would collide with them.
wt_dir="$root/worktrees/$branch_dir"
if ! git --git-dir="$root/.git" worktree add --no-checkout "$wt_dir" "$branch"; then
  # Undo: un-bare the repo and put everything back where it was.
  trap - ERR
  git -C "$root" config core.bare false
  while IFS= read -r e; do
    base="$(basename "$e")"
    if [[ "$base" == .claude && -d "$root/.claude" ]]; then
      # .claude was split, not moved whole; merge its entries back.
      while IFS= read -r sub; do
        sb="$(basename "$sub")"
        if [[ "$sb" == memory && -d "$root/.claude/memory" ]]; then
          while IFS= read -r m; do
            mv "$m" "$root/.claude/memory/$(basename "$m")"
          done < <(find "$sub" -mindepth 1 -maxdepth 1)
          rmdir "$sub"
        else
          mv "$sub" "$root/.claude/$sb"
        fi
      done < <(find "$e" -mindepth 1 -maxdepth 1)
      rmdir "$e"
      continue
    fi
    mv "$e" "$root/$base"
  done < <(find "$staging" -mindepth 1 -maxdepth 1 2>/dev/null)
  rmdir "$staging" 2>/dev/null || :
  echo "git worktree add failed — conversion rolled back:" >&2
  echo "  core.bare restored to false, staged entries moved back to $root" >&2
  echo "  (if a partial worktrees/ directory remains, it is safe to inspect)" >&2
  echo "  pre-conversion capture kept at $preflight_file" >&2
  exit 1
fi

# Step 7: the working tree files land in the worktree. worktree add created a
# .git *file* there; nothing staged can collide with it (the project's .git
# was a directory and stayed at the root).
while IFS= read -r e; do
  base="$(basename "$e")"
  if [[ -e "$wt_dir/$base" ]]; then
    # Only .claude can already exist (partial split); merge one level down.
    if [[ "$base" == .claude && -d "$e" && -d "$wt_dir/$base" ]]; then
      while IFS= read -r sub; do
        mv "$sub" "$wt_dir/$base/$(basename "$sub")"
      done < <(find "$e" -mindepth 1 -maxdepth 1)
      rmdir "$e"
      continue
    fi
    echo "unexpected collision: $wt_dir/$base already exists — left in staging" >&2
    continue
  fi
  mv "$e" "$wt_dir/$base"
done < <(find "$staging" -mindepth 1 -maxdepth 1)
rmdir "$staging"

# Rebuild the index from HEAD so pre-existing modifications stay dirty and
# untracked files stay untracked — exactly the state the checkout had.
git -C "$wt_dir" reset -q

# Step 8: bring pre-existing linked worktrees home. Each move is recorded as
# "old-relative|new-relative" so the inventory check can follow moved paths.
wt_moves=()
for i in "${!linked_worktrees[@]}"; do
  p="${linked_worktrees[$i]}"
  wname="${linked_wt_names[$i]}"
  if [[ "$p" == "$root/worktrees/"* ]]; then
    echo "  worktree $p already under worktrees/ — left alone"
    continue
  fi
  if [[ ! -e "$p/.git" ]]; then
    echo "  worktree $p is ORPHANED (gitdir missing) — not touched; recover or prune it yourself"
    continue
  fi
  if [[ -e "$root/worktrees/$wname" ]]; then
    echo "  worktrees/$wname already exists — $p left where it is; move it yourself"
    continue
  fi
  git --git-dir="$root/.git" worktree move "$p" "$root/worktrees/$wname"
  echo "  moved worktree $p → worktrees/$wname"
  if [[ "$p" == "$root/"* ]]; then
    wt_moves+=("${p#"$root"/}|worktrees/$wname")
  fi
done

# Old-layout leftovers under .claude/worktrees that were not registered
# worktrees stay put; say so rather than guessing what they are. The emptied
# directory itself also stays — nothing is deleted, and the inventory
# guarantee counts it.
if [[ -d "$root/.claude/worktrees" ]] \
   && [[ -n "$(find "$root/.claude/worktrees" -mindepth 1 -maxdepth 1 2>/dev/null | head -n1)" ]]; then
  echo "  .claude/worktrees still has entries that are not registered worktrees — left for you to inspect"
fi

# Step 9: build the space around the repo. Unlike a re-adopt (case A), a
# conversion regenerates the marker and memory seed unconditionally: whatever
# survived from the old layout describes a shape that no longer exists.
mkdir -p "$root/.claude"
echo "Directories:"
scaffold_dirs "$root"
write_hyper_md "$root" "$name"
echo "  wrote    HYPER.md (regenerated for the bare layout)"
ensure_agent_docs "$root" "$name"
write_memory_seed "$root" "$name"
echo "  wrote    .hyper/memory/hyper-layout.md (regenerated)"

# Step 10: the conversion must be provably lossless before it may claim
# success. Four guarantees, each checked against the pre-capture; any
# mismatch is a loud failure (exit 1) — never a shrug.
guarantee_failures=()

# Guarantee 1: refs byte-for-byte.
post_refs="$(git --git-dir="$root/.git" for-each-ref --format='%(refname) %(objectname)' 2>/dev/null || :)"
if [[ "$post_refs" != "$pre_refs" ]]; then
  guarantee_failures+=("REFS differ:
--- before ---
$pre_refs
--- after ---
$post_refs")
fi

# Guarantee 2: stashes.
post_stash_list="$(git -C "$wt_dir" stash list 2>/dev/null || :)"
post_stash_count=0
[[ -n "$post_stash_list" ]] && post_stash_count="$(wc -l <<<"$post_stash_list" | tr -d ' ')"
post_stash_hash="$(git -C "$wt_dir" rev-parse -q --verify refs/stash 2>/dev/null || echo none)"
if [[ "$post_stash_count" != "$pre_stash_count" || "$post_stash_hash" != "$pre_stash_hash" ]]; then
  guarantee_failures+=("STASH differs: count $pre_stash_count → $post_stash_count, refs/stash $pre_stash_hash → $post_stash_hash")
fi

# Guarantee 3: the worktree's status must match the checkout's pre-conversion
# status, minus the entries that stayed at the space root.
post_state="$(git -C "$wt_dir" status --porcelain=v1 2>/dev/null)" || post_state=""
pre_norm="$pre_state"
for k in "${keep_space[@]}" ".claude/memory/hyper-layout.md"; do
  pre_norm="$(awk -v k="$k" 'substr($0, 4, length(k)) != k' <<< "$pre_norm")"
done
if [[ "$pre_norm" != "$post_state" ]]; then
  note=""
  [[ $memory_stripped -eq 1 ]] \
    && note="(.claude/MEMORY.md had its hyper-layout line moved to the space root, which can account for a MEMORY.md difference.)"
  guarantee_failures+=("STATUS differs in the new worktree:
--- before conversion (normalized) ---
$pre_norm
--- after conversion (worktrees/$branch_dir) ---
$post_state
$note")
fi

# Guarantee 4: every pre-conversion path still exists — under the worktree,
# at the space root, or inside a moved worktree. Path-set comparison; a
# matching count proves nothing.
# -e follows symlinks, so a dangling link — routine inside node_modules, and
# often dangling before the conversion ever ran — would read as lost data and
# fail a flawless conversion. -L sees the link itself.
_present() { [[ -e "$1" || -L "$1" ]]; }
missing_paths=""
while IFS= read -r p; do
  [[ -n "$p" ]] || continue
  _present "$wt_dir/$p" || _present "$root/$p" && continue
  located=0
  for m in "${wt_moves[@]}"; do
    old="${m%%|*}"; new="${m#*|}"
    if [[ "$p" == "$old" || "$p" == "$old"/* ]]; then
      rest="${p#"$old"}"
      _present "$root/$new$rest" && located=1 && break
    fi
  done
  [[ $located -eq 1 ]] || missing_paths+="${missing_paths:+$'\n'}  $p"
done <<< "$pre_inventory"
if [[ -n "$missing_paths" ]]; then
  guarantee_failures+=("INVENTORY: these pre-conversion paths could not be located anywhere:
$missing_paths")
fi

trap - ERR

if [[ ${#guarantee_failures[@]} -gt 0 ]]; then
  echo >&2
  echo "########################################################################" >&2
  echo "# CONVERSION VERIFICATION FAILED — do not trust this space yet.        #" >&2
  echo "########################################################################" >&2
  echo "Nothing was deleted. The differences:" >&2
  for gf in "${guarantee_failures[@]}"; do
    echo >&2
    printf '%s\n' "$gf" >&2
  done
  echo >&2
  echo "The pre-conversion capture is saved at:" >&2
  echo "  $preflight_file" >&2
  [[ -d "$staging" ]] && echo "Staging dir still present: $staging" >&2
  echo "Reconcile by hand before using the space." >&2
  exit 1
fi

# All four guarantees held; the evidence file is ours and no longer needed.
rm -f "$preflight_file"

# Step 11: wire the worktree's auto memory. Deliberately after verification —
# settings.local.json is a new untracked file inside the worktree, and writing
# it earlier would surface in the status-parity check as a difference the
# conversion did not cause.
write_worktree_settings "$root" "$wt_dir"

echo
report_loose_entries "$root"
report_worktree_dir "$root"

echo
echo "Converted. All four data-safety guarantees held:"
echo "  refs identical, stashes intact ($pre_stash_count), status parity,"
echo "  all $pre_inv_count pre-conversion paths accounted for."
echo
echo "The repository is now a bare space:"
echo "  project files:  worktrees/$branch_dir/"
echo "  space-local:    data/ notes/ scratch/ bin/ (never committed)"
echo
echo "Next steps:"
echo "  cd $root/worktrees/$branch_dir"
echo "  /hyper:tools   wire the project's linter/typechecker into the check hook"
echo "  /hyper:audit   review what the conversion parked (see warnings above)"
echo "  inspect anything announced as parked or left behind — cleanup is yours"
